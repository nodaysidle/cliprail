import Foundation

/// Constants and helpers used across ClipRail.
enum ClipRailConstants {
    static let maxHistoryCount = 10
    static let maxPinnedCount = 3
    static let dedupeWindow: TimeInterval = 60
    static let pollInterval: TimeInterval = 1.0
    static let appName = "ClipRail"
    static let bundleIdentifier = "com.nodaysidle.cliprail"
    static let userDefaultsSuiteName = "com.nodaysidle.cliprail"
    static let userDefaultsKey = "cliprail_history"
}

/// Volt accent color: #C8FF00
/// Stored as a hex string; converted to SwiftUI Color in views.
enum VoltColor {
    static let hex = "#C8FF00"
    static let red: Double = 0x00C8 / 255.0   // actually 200/255
    static let green: Double = 0x00FF / 255.0 // 255/255
    static let blue: Double = 0x0000 / 255.0  // 0/255

    // Recalculated properly:
    // #C8FF00 = R:0xC8 (200), G:0xFF (255), B:0x00 (0)
    static let r: Double = 200.0 / 255.0
    static let g: Double = 255.0 / 255.0
    static let b: Double = 0.0 / 255.0
}
