import SwiftUI

/// Dark popover UI showing clipboard history list, clear button, and empty state.
/// Clicking a row re-copies that item's text to the pasteboard.
struct ContentView: View {
    @ObservedObject var store: HistoryStore
    @State private var timestampAnchor = Date()

    var body: some View {
        VStack(spacing: 0) {
            headerView

            Divider()
                .background(VoltColor.swiftUIColor.opacity(0.3))

            if store.displayItems.isEmpty {
                emptyStateView
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

    // MARK: - History list

    private var historyListView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(store.displayItems) { item in
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
        min(max(CGFloat(store.displayItems.count) * 58, 120), 320)
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
        }
        .padding(.horizontal, 14)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: timestampAnchor)
    }
}

extension VoltColor {
    static var swiftUIColor: Color {
        Color(red: r, green: g, blue: b)
    }
}