import Foundation
import AppKit

/// Polls NSPasteboard.general.changeCount to detect new text clipboard entries.
/// Runs a Timer on the main run loop (MainActor). When a new string is detected,
/// appends it to the shared HistoryStore.
@MainActor
final class ClipboardWatcher {
    private var lastChangeCount: Int = NSPasteboard.general.changeCount
    private var timer: Timer?
    private let store: HistoryStore
    private let interval: TimeInterval

    init(store: HistoryStore, interval: TimeInterval = ClipRailConstants.pollInterval) {
        self.store = store
        self.interval = interval
    }

    func start() {
        guard timer == nil else { return }
        lastChangeCount = NSPasteboard.general.changeCount
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.poll()
            }
        }
        // Ensure the timer fires on the main run loop in the common run loop mode
        if let t = timer {
            RunLoop.main.add(t, forMode: .common)
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func poll() {
        let currentChangeCount = NSPasteboard.general.changeCount
        guard currentChangeCount != lastChangeCount else { return }
        lastChangeCount = currentChangeCount

        // Defer the pasteboard read by a short interval. On macOS the
        // changeCount can increment before the new string is fully written,
        // so an immediate read may return the *previous* clipboard value.
        // A small delay lets the write settle before we capture the text.
        Task { @MainActor [weak self] in
            guard let self else { return }
            try? await Task.sleep(nanoseconds: 50_000_000) // 50 ms
            guard let newString = NSPasteboard.general.string(forType: .string),
                  ClipboardItem.isValid(newString)
            else { return }
            self.store.append(text: newString)
        }
    }
}
