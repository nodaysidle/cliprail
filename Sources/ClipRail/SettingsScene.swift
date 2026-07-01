import SwiftUI

/// Minimal settings/about window (not a popover inside the menu bar popover).
struct SettingsView: View {
    var body: some View {
        TabView {
            AboutTab()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 380, height: 260)
    }
}

private struct AboutTab: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            // App icon placeholder
            if let appIcon = NSImage(named: NSImage.applicationIconName) {
                Image(nsImage: appIcon)
                    .resizable()
                    .frame(width: 64, height: 64)
            } else {
                Image(systemName: "clipboard")
                    .font(.system(size: 48))
                    .foregroundColor(VoltColor.swiftUIColor)
            }

            Text("ClipRail")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text("Version 1.0.0 (Slice 1)")
                .font(.caption)
                .foregroundColor(.secondary)

            Text("Menu bar clipboard history.\nLocal only. No network. No images.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            Text("Volt accent · Dark UI · macOS 14+")
                .font(.caption2)
                .foregroundColor(.gray.opacity(0.6))

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
    }
}
