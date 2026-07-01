import XCTest
@testable import ClipRail

@MainActor
final class HistoryStoreTests: XCTestCase {
    private var suite: UserDefaults!
    private var suiteName: String!
    private let storageKey = "test_cliprail_history"

    override func setUp() async throws {
        try await super.setUp()
        suiteName = "com.nodaysidle.cliprail.tests.\(UUID().uuidString)"
        suite = UserDefaults(suiteName: suiteName)
        suite.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() async throws {
        suite.removePersistentDomain(forName: suiteName)
        suite = nil
        suiteName = nil
        try await super.tearDown()
    }

    private func makeStore(
        maxCount: Int = ClipRailConstants.maxHistoryCount,
        maxPinnedCount: Int = ClipRailConstants.maxPinnedCount,
        dedupeWindow: TimeInterval = ClipRailConstants.dedupeWindow
    ) -> HistoryStore {
        HistoryStore(
            maxCount: maxCount,
            maxPinnedCount: maxPinnedCount,
            dedupeWindow: dedupeWindow,
            userDefaults: suite,
            storageKey: storageKey
        )
    }

    // MARK: - Append

    func testAppendAddsItem() {
        let store = makeStore()
        store.append(text: "Hello World")
        XCTAssertEqual(store.items.count, 1)
        XCTAssertEqual(store.items[0].text, "Hello World")
    }

    func testAppendSkipsEmptyText() {
        let store = makeStore()
        store.append(text: "")
        store.append(text: "   ")
        XCTAssertEqual(store.items.count, 0)
    }

    func testAppendDeduplicatesWithinWindow() {
        let store = makeStore(dedupeWindow: 60)
        let t0 = Date(timeIntervalSince1970: 1_700_000_000)
        store.append(text: "first", now: t0)
        store.append(text: "second", now: t0.addingTimeInterval(5))
        store.append(text: "first", now: t0.addingTimeInterval(10))

        XCTAssertEqual(store.unpinnedItems.count, 2)
        XCTAssertEqual(store.unpinnedItems[0].text, "first")
        XCTAssertEqual(store.unpinnedItems[1].text, "second")
        XCTAssertEqual(store.unpinnedItems[0].copiedAt, t0.addingTimeInterval(10))
    }

    func testAppendDoesNotDeduplicateOutsideWindow() {
        let store = makeStore(dedupeWindow: 60)
        let t0 = Date(timeIntervalSince1970: 1_700_000_000)
        store.append(text: "first", now: t0)
        store.append(text: "first", now: t0.addingTimeInterval(61))

        XCTAssertEqual(store.unpinnedItems.count, 2)
        XCTAssertEqual(store.unpinnedItems.map(\.text), ["first", "first"])
    }

    func testAppendNewestFirstAmongUnpinned() {
        let store = makeStore()
        let t0 = Date(timeIntervalSince1970: 1_700_000_000)
        store.append(text: "A", now: t0)
        store.append(text: "B", now: t0.addingTimeInterval(1))
        store.append(text: "C", now: t0.addingTimeInterval(2))
        XCTAssertEqual(store.unpinnedItems.map(\.text), ["C", "B", "A"])
    }

    // MARK: - Max Count

    func testMaxCountTrimsUnpinnedOnly() {
        let store = makeStore(maxCount: 3)
        let t0 = Date(timeIntervalSince1970: 1_700_000_000)
        for i in 1...4 {
            store.append(text: "\(i)", now: t0.addingTimeInterval(Double(i)))
        }
        XCTAssertEqual(store.unpinnedItems.count, 3)
        XCTAssertEqual(store.unpinnedItems.map(\.text), ["4", "3", "2"])
    }

    func testPinnedItemsDoNotCountTowardUnpinnedLimit() {
        let store = makeStore(maxCount: 2, maxPinnedCount: 2)
        let t0 = Date(timeIntervalSince1970: 1_700_000_000)
        store.append(text: "pin-me", now: t0)
        _ = store.togglePin(store.items[0])
        store.append(text: "one", now: t0.addingTimeInterval(1))
        store.append(text: "two", now: t0.addingTimeInterval(2))
        store.append(text: "three", now: t0.addingTimeInterval(3))

        XCTAssertEqual(store.pinnedItems.count, 1)
        XCTAssertEqual(store.unpinnedItems.count, 2)
        XCTAssertEqual(store.unpinnedItems.map(\.text), ["three", "two"])
    }

    // MARK: - Pin

    func testTogglePinAddsAndRemovesPin() {
        let store = makeStore()
        store.append(text: "pinned")
        let item = store.items[0]
        XCTAssertTrue(store.togglePin(item))
        XCTAssertTrue(store.pinnedItems[0].isPinned)

        XCTAssertTrue(store.togglePin(store.pinnedItems[0]))
        XCTAssertEqual(store.pinnedItems.count, 0)
        XCTAssertEqual(store.unpinnedItems[0].text, "pinned")
    }

    func testMaxPinnedCountEnforced() {
        let store = makeStore(maxPinnedCount: 2)
        let t0 = Date(timeIntervalSince1970: 1_700_000_000)
        store.append(text: "a", now: t0)
        store.append(text: "b", now: t0.addingTimeInterval(1))
        store.append(text: "c", now: t0.addingTimeInterval(2))

        XCTAssertTrue(store.togglePin(store.unpinnedItems[0]))
        XCTAssertTrue(store.togglePin(store.unpinnedItems[0]))
        XCTAssertFalse(store.togglePin(store.unpinnedItems[0]))
        XCTAssertEqual(store.pinnedItems.count, 2)
    }

    func testPinnedItemSurvivesClear() {
        let store = makeStore()
        let t0 = Date(timeIntervalSince1970: 1_700_000_000)
        store.append(text: "keep", now: t0)
        store.append(text: "drop", now: t0.addingTimeInterval(1))
        _ = store.togglePin(store.items.first { $0.text == "keep" }!)

        store.clear()

        XCTAssertEqual(store.items.count, 1)
        XCTAssertEqual(store.items[0].text, "keep")
        XCTAssertTrue(store.items[0].isPinned)
    }

    // MARK: - Clear

    func testClearRemovesOnlyUnpinnedItems() {
        let store = makeStore()
        store.append(text: "A")
        store.append(text: "B")
        store.clear()
        XCTAssertEqual(store.items.count, 0)
    }

    func testClearPersists() {
        let store = makeStore()
        store.append(text: "A")
        store.clear()
        let store2 = makeStore()
        XCTAssertEqual(store2.items.count, 0)
    }

    // MARK: - Persistence Roundtrip

    func testPersistenceRoundtrip() {
        let store1 = makeStore()
        let t0 = Date(timeIntervalSince1970: 1_700_000_000)
        store1.append(text: "Persisted A", now: t0)
        store1.append(text: "Persisted B", now: t0.addingTimeInterval(1))
        _ = store1.togglePin(store1.items.first { $0.text == "Persisted A" }!)

        let store2 = makeStore()
        XCTAssertEqual(store2.items.count, 2)
        XCTAssertEqual(store2.pinnedItems[0].text, "Persisted A")
        XCTAssertEqual(store2.unpinnedItems[0].text, "Persisted B")
    }

    func testEmptyStoreDoesNotCrashOnLoad() {
        _ = makeStore()
    }

    // MARK: - Edge Cases

    func testAppendVeryLongText() {
        let store = makeStore()
        let longText = String(repeating: "Lorem ipsum dolor sit amet. ", count: 500)
        store.append(text: longText)
        XCTAssertEqual(store.items.count, 1)
    }

    func testAppendMultipleDuplicatesInSuccessionWithinWindow() {
        let store = makeStore(dedupeWindow: 60)
        let t0 = Date(timeIntervalSince1970: 1_700_000_000)
        for offset in 0..<5 {
            store.append(text: "same", now: t0.addingTimeInterval(Double(offset)))
        }
        XCTAssertEqual(store.items.count, 1)
    }
}