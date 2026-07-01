import XCTest
@testable import ClipRail

@MainActor
final class HistoryStoreTests: XCTestCase {
    private var suite: UserDefaults!
    private var suiteName: String!
    private let storageKey = "test_cliprail_history"

    override func setUp() async throws {
        try await super.setUp()
        // Use a temporary suite to avoid polluting real defaults
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

    private func makeStore(maxCount: Int = ClipRailConstants.maxHistoryCount) -> HistoryStore {
        HistoryStore(maxCount: maxCount, userDefaults: suite, storageKey: storageKey)
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

    func testAppendDeduplicatesByText() {
        let store = makeStore()
        store.append(text: "first")
        store.append(text: "second")
        store.append(text: "first") // duplicate
        XCTAssertEqual(store.items.count, 2)
        // Most recent should be "first" at index 0
        XCTAssertEqual(store.items[0].text, "first")
        XCTAssertEqual(store.items[1].text, "second")
    }

    func testAppendNewestFirst() {
        let store = makeStore()
        store.append(text: "A")
        store.append(text: "B")
        store.append(text: "C")
        XCTAssertEqual(store.items.map(\.text), ["C", "B", "A"])
    }

    // MARK: - Max Count

    func testMaxCountTrimsHistory() {
        let store = makeStore(maxCount: 3)
        store.append(text: "1")
        store.append(text: "2")
        store.append(text: "3")
        store.append(text: "4")
        XCTAssertEqual(store.items.count, 3)
        XCTAssertEqual(store.items.map(\.text), ["4", "3", "2"])
    }

    func testMaxCountObservesConfigurableLimit() {
        let store = makeStore(maxCount: 5)
        for i in 1...10 {
            store.append(text: "item\(i)")
        }
        XCTAssertEqual(store.items.count, 5)
    }

    // MARK: - Clear

    func testClearRemovesAllItems() {
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
        // Create a new store reading from same defaults
        let store2 = makeStore()
        XCTAssertEqual(store2.items.count, 0)
    }

    // MARK: - Persistence Roundtrip

    func testPersistenceRoundtrip() {
        let store1 = makeStore()
        store1.append(text: "Persisted A")
        store1.append(text: "Persisted B")

        // New store with same UserDefaults/key should load saved items
        let store2 = makeStore()
        XCTAssertEqual(store2.items.count, 2)
        XCTAssertEqual(store2.items[0].text, "Persisted B")
        XCTAssertEqual(store2.items[1].text, "Persisted A")
    }

    func testEmptyStoreDoesNotCrashOnLoad() {
        _ = makeStore()
        // Just verifying no crash on init with empty defaults
    }

    // MARK: - Edge Cases

    func testAppendVeryLongText() {
        let store = makeStore()
        let longText = String(repeating: "Lorem ipsum dolor sit amet. ", count: 500)
        store.append(text: longText)
        XCTAssertEqual(store.items.count, 1)
    }

    func testAppendMultipleDuplicatesInSuccession() {
        let store = makeStore()
        for _ in 1...5 {
            store.append(text: "same")
        }
        // Should always have just 1 entry for "same"
        XCTAssertEqual(store.items.count, 1)
    }
}
