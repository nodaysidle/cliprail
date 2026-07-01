import SwiftUI

/// Dark popover UI showing clipboard history list, clear button, and empty state.
/// Clicking a row re-copies that item's text to the pasteboard.
struct ContentView: View {
    @ObservedObject var store: HistoryStore
    @State private var timestampAnchor = Date()
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool

    private var filteredItems: [ClipboardItem] {
        HistoryStore.filterItems(store.displayItems, matching: searchText)
    }

    var body: some View {
        VStack(spacing: 0) {
            headerView

            pauseBannerView

            searchFieldView

            Divider()
                .background(VoltColor.swiftUIColor.opacity(0.3))

            if store.displayItems.isEmpty {
                emptyStateView
            } else if filteredItems.isEmpty {
                noMatchView
            } else {
                historyListView
                    .frame(height: historyListHeight)
            }
        }
        .frame(width: 340)
        .background(Color.black)
        .onAppear {
            timestampAnchor = Date()
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Text("ClipRail")
                .font(.headline)
                .foregroundColor(.white)

            Spacer()

            pauseToggleButton

            Button(action: { store.clear() }) {
                Text("Clear")
                    .font(.caption)
                    .foregroundColor(VoltColor.swiftUIColor)
            }
            .buttonStyle(.plain)
            .disabled(store.unpinnedItems.isEmpty)
            .help("Clear unpinned clips. Pinned clips are kept.")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Pause toggle

    private var pauseToggleButton: some View {
        Button(action: { store.isPaused.toggle() }) {
            Text(store.isPaused ? "Resume" : "Pause")
                .font(.caption)
                .foregroundColor(store.isPaused ? Color.orange : VoltColor.swiftUIColor)
        }
        .buttonStyle(.plain)
        .help(store.isPaused ? "Resume clipboard capture" : "Pause clipboard capture")
    }

    // MARK: - Pause banner

    @ViewBuilder
    private var pauseBannerView: some View {
        if store.isPaused {
            HStack(spacing: 6) {
                Image(systemName: "pause.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.orange)
                Text("Capture paused")
                    .font(.caption)
                    .foregroundColor(.orange.opacity(0.8))
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(Color.orange.opacity(0.1))
        }
    }

    // MARK: - Search field

    private var searchFieldView: some View {
        TextField("Search clips…", text: $searchText)
            .textFieldStyle(.plain)
            .font(.system(size: 12))
            .foregroundColor(.white)
            .padding(8)
            .background(Color.white.opacity(0.08))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isSearchFocused ? VoltColor.swiftUIColor : Color.clear, lineWidth: 1.5)
            )
            .focused($isSearchFocused)
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
    }

    // MARK: - Empty state

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Spacer(minLength: 40)
            Image(systemName: "clipboard")
                .font(.system(size: 32))
                .foregroundColor(.gray.opacity(0.5))
            Text("No clipboard history")
                .font(.body)
                .foregroundColor(.gray.opacity(0.7))
            Text("Copy text (⌘C) to see it here")
                .font(.caption)
                .foregroundColor(.gray.opacity(0.5))
            Spacer(minLength: 40)
        }
        .frame(maxWidth: .infinity)
        .background(Color.black)
    }

    // MARK: - No search match state

    private var noMatchView: some View {
        VStack(spacing: 12) {
            Spacer(minLength: 40)
            Image(systemName: "magnifyingglass")
                .font(.system(size: 32))
                .foregroundColor(.gray.opacity(0.5))
            Text("No matching clips")
                .font(.body)
                .foregroundColor(.gray.opacity(0.7))
            Spacer(minLength: 40)
        }
        .frame(maxWidth: .infinity)
        .background(Color.black)
    }

    // MARK: - History list

    private var historyListView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(filteredItems) { item in
                    historyRow(item)
                    Divider()
                        .background(Color.gray.opacity(0.15))
                        .padding(.leading, 14)
                }
            }
        }
        .background(Color.black)
    }

    private var historyListHeight: CGFloat {
        min(max(CGFloat(filteredItems.count) * 58, 120), 320)
    }

    private func historyRow(_ item: ClipboardItem) -> some View {
        HStack(spacing: 8) {
            Button(action: { _ = store.togglePin(item) }) {
                Image(systemName: item.isPinned ? "star.fill" : "star")
                    .font(.system(size: 12))
                    .foregroundColor(
                        item.isPinned
                            ? VoltColor.swiftUIColor
                            : (store.canPinMore ? Color.gray.opacity(0.5) : Color.gray.opacity(0.25))
                    )
            }
            .buttonStyle(.plain)
            .disabled(!item.isPinned && !store.canPinMore)
            .help(item.isPinned ? "Unpin clip" : "Pin clip (max 3)")

            Button(action: { HistoryStore.copyToPasteboard(item) }) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.preview())
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Text(formattedDate(item.copiedAt))
                        .font(.system(size: 10))
                        .foregroundColor(.gray.opacity(0.5))
                }
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Copy clip: \(item.preview(maxLength: 80))")

            Button(action: { store.deleteItem(item.id) }) {
                Image(systemName: "trash")
                    .font(.system(size: 11))
                    .foregroundColor(.gray.opacity(0.4))
            }
            .buttonStyle(.plain)
            .help("Delete clip")
        }
        .padding(.horizontal, 14)
    }

    private func formattedDate(_ date: Date) -> String {
        HistoryStore.formattedRelativeDate(date, relativeTo: timestampAnchor)
    }
}

extension VoltColor {
    static var swiftUIColor: Color {
        Color(red: r, green: g, blue: b)
    }
}
