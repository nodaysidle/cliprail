import SwiftUI

/// Dark popover UI showing clipboard history list, clear button, and empty state.
/// Clicking a row re-copies that item's text to the pasteboard.
struct ContentView: View {
    @ObservedObject var store: HistoryStore

    var body: some View {
        VStack(spacing: 0) {
            // Header with title and clear button
            headerView

            Divider()
                .background(VoltColor.swiftUIColor.opacity(0.3))

            // Content area
            if store.items.isEmpty {
                emptyStateView
            } else {
                historyListView
                    .frame(height: historyListHeight)
            }
        }
        .frame(width: 340)
        .background(Color.black)
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
            .disabled(store.items.isEmpty)
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
                ForEach(store.items) { item in
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
        min(max(CGFloat(store.items.count) * 58, 120), 320)
    }

    private func historyRow(_ item: ClipboardItem) -> some View {
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
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Copy clip: \(item.preview(maxLength: 80))")
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

extension VoltColor {
    static var swiftUIColor: Color {
        Color(red: r, green: g, blue: b)
    }
}
