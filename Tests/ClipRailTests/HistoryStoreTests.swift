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

    // MARK: - Slice 3: Search

    func testSearchEmptyQueryReturnsAll() {
        let store = makeStore()
        let t0 = Date(timeIntervalSince1970: 1_700_000_000)
        store.append(text: "Apple", now: t0)
        store.append(text: "Banana", now: t0.addingTimeInterval(1))
        store.append(text: "Cherry", now: t0.addingTimeInterval(2))

        let result = HistoryStore.filterItems(store.displayItems, matching: "")
        XCTAssertEqual(result.count, 3)
    }

    func testSearchWhitespaceOnlyReturnsAll() {
        let store = makeStore()
        let t0 = Date(timeIntervalSince1970: 1_700_000_000)
        store.append(text: "Apple", now: t0)
        store.append(text: "Banana", now: t0.addingTimeInterval(1))

        let result = HistoryStore.filterItems(store.displayItems, matching: "   ")
        XCTAssertEqual(result.count, 2)
    }

    func testSearchCaseInsensitiveContains() {
        let store = makeStore()
        let t0 = Date(timeIntervalSince1970: 1_700_000_000)
        store.append(text: "Apple Pie", now: t0)
        store.append(text: "Banana", now: t0.addingTimeInterval(1))
        store.append(text: "pineapple", now: t0.addingTimeInterval(2))

        let result = HistoryStore.filterItems(store.displayItems, matching: "APPLE")
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.map(\.text).contains("Apple Pie"))
        XCTAssertTrue(result.map(\.text).contains("pineapple"))
    }

    func testSearchNoMatchReturnsEmpty() {
        let store = makeStore()
        let t0 = Date(timeIntervalSince1970: 1_700_000_000)
        store.append(text: "Apple", now: t0)
        store.append(text: "Banana", now: t0.addingTimeInterval(1))

        let result = HistoryStore.filterItems(store.displayItems, matching: "ZZZ")
        XCTAssertEqual(result.count, 0)
    }

    func testSearchPreservesPinnedFirstOrder() {
        let store = makeStore()
        let t0 = Date(timeIntervalSince1970: 1_700_000_000)
        store.append(text: "Zebra Apple", now: t0)
        store.append(text: "Apple Zebra", now: t0.addingTimeInterval(1))
        _ = store.togglePin(store.items.first { $0.text == "Apple Zebra" }!)

        let result = HistoryStore.filterItems(store.displayItems, matching: "apple")
        XCTAssertEqual(result.count, 2)
        // Pinned item should be first
        XCTAssertTrue(result[0].isPinned)
        XCTAssertEqual(result[0].text, "Apple Zebra")
    }

    // MARK: - Slice 3: Delete

    func testDeleteSingleUnpinnedItem() {
        let store = makeStore()
        let t0 = Date(timeIntervalSince1970: 1_700_000_000)
        store.append(text: "A", now: t0)
        store.append(text: "B", now: t0.addingTimeInterval(1))
        store.append(text: "C", now: t0.addingTimeInterval(2))

        let itemB = store.items.first { $0.text == "B" }!
        store.deleteItem(itemB.id)

        XCTAssertEqual(store.items.count, 2)
        XCTAssertEqual(store.unpinnedItems.map(\.text), ["C", "A"])
    }

    func testDeleteSinglePinnedItem() {
        let store = makeStore()
        let t0 = Date(timeIntervalSince1970: 1_700_000_000)
        store.append(text: "A", now: t0)
        store.append(text: "B", now: t0.addingTimeInterval(1))
        _ = store.togglePin(store.items.first { $0.text == "A" }!)

        let pinnedA = store.pinnedItems[0]
        store.deleteItem(pinnedA.id)

        XCTAssertEqual(store.items.count, 1)
        XCTAssertEqual(store.pinnedItems.count, 0)
        XCTAssertEqual(store.unpinnedItems[0].text, "B")
    }

    func testDeletePersistsImmediately() {
        let store1 = makeStore()
        let t0 = Date(timeIntervalSince1970: 1_700_000_000)
        store1.append(text: "Keep", now: t0)
        store1.append(text: "Remove", now: t0.addingTimeInterval(1))

        let removeItem = store1.items.first { $0.text == "Remove" }!
        store1.deleteItem(removeItem.id)

        // New store should only have "Keep"
        let store2 = makeStore()
        XCTAssertEqual(store2.items.count, 1)
        XCTAssertEqual(store2.items[0].text, "Keep")
    }

    func testDeleteOnlyRemovesTargetItem() {
        let store = makeStore()
        let t0 = Date(timeIntervalSince1970: 1_700_000_000)
        store.append(text: "A", now: t0)
        store.append(text: "B", now: t0.addingTimeInterval(1))
        store.append(text: "A", now: t0.addingTimeInterval(61)) // outside dedupe window

        let firstA = store.items.first { $0.text == "A" && $0.copiedAt == t0 }!
        store.deleteItem(firstA.id)

        // The second "A" should still be there
        XCTAssertEqual(store.items.count, 2)
        XCTAssertTrue(store.items.contains(where: { $0.text == "A" }))
        XCTAssertTrue(store.items.contains(where: { $0.text == "B" }))
    }

    // MARK: - Slice 3: Pause

    func testPauseStopsAppend() {
        let store = makeStore()
        store.append(text: "Before Pause")
        XCTAssertEqual(store.items.count, 1)

        store.isPaused = true
        store.append(text: "During Pause")
        XCTAssertEqual(store.items.count, 1)
    }

    func testResumeAllowsAppend() {
        let store = makeStore()
        store.isPaused = true
        store.append(text: "During Pause")
        XCTAssertEqual(store.items.count, 0)

        store.isPaused = false
        store.append(text: "After Resume")
        XCTAssertEqual(store.items.count, 1)
        XCTAssertEqual(store.items[0].text, "After Resume")
    }

    func testPausedAppendNotReplayed() {
        let store = makeStore()
        store.isPaused = true
        store.append(text: "Skipped1")
        store.append(text: "Skipped2")
        XCTAssertEqual(store.items.count, 0)

        store.isPaused = false
        store.append(text: "Only This")
        XCTAssertEqual(store.items.count, 1)
        XCTAssertEqual(store.items[0].text, "Only This")
    }

    func testPauseDoesNotAffectExistingItems() {
        let store = makeStore()
        let t0 = Date(timeIntervalSince1970: 1_700_000_000)
        store.append(text: "Existing", now: t0)
        _ = store.togglePin(store.items[0])

        store.isPaused = true

        // Existing items should still be accessible for operations
        XCTAssertEqual(store.items.count, 1)
        store.deleteItem(store.items[0].id)
        XCTAssertEqual(store.items.count, 0)
    }

    // MARK: - Slice 2 Regression: Relative Timestamps on Appear

    /// The on-appear timestamp anchor ensures every time the view appears,
    /// all relative timestamps are recalculated against a fresh anchor.
    /// This tests the pure formatting function used by ContentView.
    func testSlice2RegressionRelativeTimestampOnAppearAnchor() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let fiveMinutesAgo = now.addingTimeInterval(-300)

        // Same date relative to different anchors produces different strings
        let relativeToNow = HistoryStore.formattedRelativeDate(fiveMinutesAgo, relativeTo: now)
        let relativeToFuture = HistoryStore.formattedRelativeDate(fiveMinutesAgo, relativeTo: now.addingTimeInterval(600))

        XCTAssertFalse(relativeToNow.isEmpty)
        XCTAssertFalse(relativeToFuture.isEmpty)
        XCTAssertNotEqual(relativeToNow, relativeToFuture,
                          "Same date with different anchors should yield different relative strings")
    }

    /// Verifies that the anchor refresh (on appear) behavior produces
    /// monotonically different results: a date further in the past
    /// relative to the same anchor should not produce the same string
    /// as a date closer to the anchor.
    func testSlice2RegressionRelativeTimestampDifferentDistancesFromSameAnchor() {
        let anchor = Date(timeIntervalSince1970: 1_700_000_000)
        let oneMinuteAgo = anchor.addingTimeInterval(-60)
        let oneHourAgo = anchor.addingTimeInterval(-3600)

        let t1 = HistoryStore.formattedRelativeDate(oneMinuteAgo, relativeTo: anchor)
        let t2 = HistoryStore.formattedRelativeDate(oneHourAgo, relativeTo: anchor)

        XCTAssertFalse(t1.isEmpty)
        XCTAssertFalse(t2.isEmpty)
        XCTAssertNotEqual(t1, t2,
                          "Different distances from the same anchor should produce different strings")
    }

    /// On every appear, the anchor is set to Date(), meaning items that
    /// were "5m ago" a minute ago might now be "6m ago." This test
    /// verifies that advancing the anchor changes the output.
    func testSlice2RegressionRelativeTimestampAnchorAdvancesOnReappear() {
        let itemDate = Date(timeIntervalSince1970: 1_700_000_000)
        let firstAppearAnchor = Date(timeIntervalSince1970: 1_700_000_060)  // 60s after item
        let secondAppearAnchor = Date(timeIntervalSince1970: 1_700_000_120) // 120s after item

        let firstDisplay = HistoryStore.formattedRelativeDate(itemDate, relativeTo: firstAppearAnchor)
        let secondDisplay = HistoryStore.formattedRelativeDate(itemDate, relativeTo: secondAppearAnchor)

        XCTAssertFalse(firstDisplay.isEmpty)
        XCTAssertFalse(secondDisplay.isEmpty)
        // Advancing the anchor should change the relative timestamp
        XCTAssertNotEqual(firstDisplay, secondDisplay,
                          "Advancing the timestamp anchor should refresh relative display")
    }

    // MARK: - Slice 2 Regressions

    func testSlice2RegressionPinSurvivesClear() {
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

    func testSlice2RegressionDedupeBumpNoDuplicate() {
        let store = makeStore(dedupeWindow: 60)
        let t0 = Date(timeIntervalSince1970: 1_700_000_000)
        store.append(text: "dup", now: t0)
        store.append(text: "dup", now: t0.addingTimeInterval(30))

        XCTAssertEqual(store.items.count, 1)
        XCTAssertEqual(store.items[0].copiedAt, t0.addingTimeInterval(30))
    }
}
