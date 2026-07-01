import Foundation
import AppKit

/// Manages clipboard history: append, dedup, clear, persist to UserDefaults.
/// @MainActor since AppKit pasteboard access requires the main thread.
@MainActor
final class HistoryStore: ObservableObject {
    @Published var items: [ClipboardItem] = []

    private let maxCount: Int
    private let userDefaults: UserDefaults
    private let storageKey: String

    init(
        maxCount: Int = ClipRailConstants.maxHistoryCount,
        userDefaults: UserDefaults = UserDefaults(suiteName: ClipRailConstants.userDefaultsSuiteName)
            ?? UserDefaults.standard,
        storageKey: String = ClipRailConstants.userDefaultsKey
    ) {
        self.maxCount = maxCount
        self.userDefaults = userDefaults
        self.storageKey = storageKey
        load()
    }

    /// Append a new clip. Deduplicates by text (existing identical clip
    /// is removed before inserting the new one at the top). Trims to maxCount.
    func append(text: String) {
        let sanitized = ClipboardItem.sanitize(text)
        guard !sanitized.isEmpty else { return }

        // Remove duplicate text
        items.removeAll { $0.text == sanitized }
        items.insert(ClipboardItem(text: sanitized), at: 0)

        if items.count > maxCount {
            items = Array(items.prefix(maxCount))
        }

        save()
    }

    /// Clear all history.
    func clear() {
        items.removeAll()
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
        items = Array(decoded.prefix(maxCount))
    }
}
