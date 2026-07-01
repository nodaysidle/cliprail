import Foundation

/// ClipboardItem is the core data model: a sanitized text clip with metadata.
/// Identifiable, Codable, Equatable, Sendable for safe storage and transfer.
struct ClipboardItem: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let text: String
    let copiedAt: Date

    init(id: UUID = UUID(), text: String, copiedAt: Date = Date()) {
        self.id = id
        self.text = ClipboardItem.sanitize(text)
        self.copiedAt = copiedAt
    }

    /// Strips control characters except newline (\n) and tab (\t),
    /// trims whitespace. Returns nil if the result is empty.
    static func sanitize(_ raw: String) -> String {
        let allowed = CharacterSet.controlCharacters
            .subtracting(CharacterSet(charactersIn: "\n\t"))
        let cleaned = raw
            .components(separatedBy: allowed)
            .joined()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned
    }

    /// Returns a preview of the text, truncating long strings.
    func preview(maxLength: Int = 120) -> String {
        let singleLine = text.replacingOccurrences(of: "\n", with: " ↵ ")
            .replacingOccurrences(of: "\t", with: " ")
        if singleLine.count <= maxLength {
            return singleLine
        }
        let index = singleLine.index(singleLine.startIndex, offsetBy: maxLength)
        return String(singleLine[..<index]) + "…"
    }

    /// Whether sanitization would produce a non-empty string.
    static func isValid(_ raw: String) -> Bool {
        !sanitize(raw).isEmpty
    }
}
