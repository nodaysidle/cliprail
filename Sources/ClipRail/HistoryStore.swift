import Foundation
import AppKit

/// Manages clipboard history: append, dedup, pin, clear, persist to UserDefaults.
/// @MainActor since AppKit pasteboard access requires the main thread.
@MainActor
final class HistoryStore: ObservableObject {
    @Published var items: [ClipboardItem] = []

    private let maxCount: Int
    private let maxPinnedCount: Int
    private let dedupeWindow: TimeInterval
    private let userDefaults: UserDefaults
    private let storageKey: String

    init(
        maxCount: Int = ClipRailConstants.maxHistoryCount,
        maxPinnedCount: Int = ClipRailConstants.maxPinnedCount,
        dedupeWindow: TimeInterval = ClipRailConstants.dedupeWindow,
        userDefaults: UserDefaults = UserDefaults(suiteName: ClipRailConstants.userDefaultsSuiteName)
            ?? UserDefaults.standard,
        storageKey: String = ClipRailConstants.userDefaultsKey
    ) {
        self.maxCount = maxCount
        self.maxPinnedCount = maxPinnedCount
        self.dedupeWindow = dedupeWindow
        self.userDefaults = userDefaults
        self.storageKey = storageKey
        load()
    }

    var pinnedItems: [ClipboardItem] {
        items.filter(\.isPinned).sorted { $0.copiedAt > $1.copiedAt }
    }

    var unpinnedItems: [ClipboardItem] {
        items.filter { !$0.isPinned }.sorted { $0.copiedAt > $1.copiedAt }
    }

    var displayItems: [ClipboardItem] {
        pinnedItems + unpinnedItems
    }

    var canPinMore: Bool {
        items.filter(\.isPinned).count < maxPinnedCount
    }

    /// Append a clip. Within the dedupe window, identical text bumps the existing row
    /// to the top of its section and refreshes the timestamp instead of adding a row.
    func append(text: String, now: Date = Date()) {
        let sanitized = ClipboardItem.sanitize(text)
        guard !sanitized.isEmpty else { return }

        if let index = items.firstIndex(where: {
            $0.text == sanitized && now.timeIntervalSince($0.copiedAt) <= dedupeWindow
        }) {
            let existing = items[index]
            let bumped = ClipboardItem(
                id: existing.id,
                text: sanitized,
                copiedAt: now,
                isPinned: existing.isPinned
            )
            items.remove(at: index)
            insertAtTop(bumped)
        } else {
            insertAtTop(ClipboardItem(text: sanitized, copiedAt: now))
        }

        trim()
        save()
    }

    /// Toggle pin state. Enforces maxPinnedCount; pinned items move to the pinned section.
    @discardableResult
    func togglePin(_ item: ClipboardItem) -> Bool {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return false }
        let current = items[index]

        if current.isPinned {
            let unpinned = ClipboardItem(
                id: current.id,
                text: current.text,
                copiedAt: current.copiedAt,
                isPinned: false
            )
            items.remove(at: index)
            insertAtTop(unpinned)
        } else {
            guard canPinMore else { return false }
            let pinned = ClipboardItem(
                id: current.id,
                text: current.text,
                copiedAt: current.copiedAt,
                isPinned: true
            )
            items.remove(at: index)
            insertAtTop(pinned)
        }

        save()
        return true
    }

    /// Remove unpinned clips only. Pinned clips survive.
    func clear() {
        items.removeAll { !$0.isPinned }
        save()
    }

    /// Copy the given item's text back to the system pasteboard.
    static func copyToPasteboard(_ item: ClipboardItem) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(item.text, forType: .string)
    }

    // MARK: - Persistence

    private func save() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        userDefaults.set(data, forKey: storageKey)
    }

    private func load() {
        guard let data = userDefaults.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([ClipboardItem].self, from: data)
        else { return }
        items = decoded
        trim()
    }

    private func insertAtTop(_ item: ClipboardItem) {
        if item.isPinned {
            items.insert(item, at: 0)
        } else {
            let firstUnpinned = items.firstIndex(where: { !$0.isPinned }) ?? items.endIndex
            items.insert(item, at: firstUnpinned)
        }
    }

    private func trim() {
        var pinned = items.filter(\.isPinned)
        var unpinned = items.filter { !$0.isPinned }

        if pinned.count > maxPinnedCount {
            pinned = Array(pinned.sorted { $0.copiedAt > $1.copiedAt }.prefix(maxPinnedCount))
        }
        if unpinned.count > maxCount {
            unpinned = Array(unpinned.sorted { $0.copiedAt > $1.copiedAt }.prefix(maxCount))
        }

        items = pinned.sorted { $0.copiedAt > $1.copiedAt }
            + unpinned.sorted { $0.copiedAt > $1.copiedAt }
    }
}