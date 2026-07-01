import SwiftUI

/// Owns app-wide state so SwiftUI renders the menu immediately and the
/// pasteboard watcher stays alive for the full app lifetime.
@MainActor
final class ClipRailAppModel: ObservableObject {
    let store: HistoryStore
    private var watcher: ClipboardWatcher?

    init(store: HistoryStore = HistoryStore()) {
        self.store = store
        startWatcherIfNeeded()
    }

    func startWatcherIfNeeded() {
        guard watcher == nil else { return }
        let newWatcher = ClipboardWatcher(store: store)
        watcher = newWatcher
        newWatcher.start()
    }
}

/// @main entry point. Uses MenuBarExtra for a menu bar icon + popover.
@main
struct ClipRailApp: App {
    @StateObject private var model = ClipRailAppModel()

    var body: some Scene {
        MenuBarExtra {
            ContentView(store: model.store)
                .task {
                    model.startWatcherIfNeeded()
                }
        } label: {
            if model.store.isPaused {
                VStack(spacing: 0) {
                    Image(systemName: "list.clipboard")
                        .font(.system(size: 10))
                    Text("⏸")
                        .font(.system(size: 6))
                }
            } else {
                Image(systemName: "list.clipboard")
            }
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
        }
    }
}
