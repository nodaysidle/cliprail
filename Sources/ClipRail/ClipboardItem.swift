import Foundation

/// ClipboardItem is the core data model: a sanitized text clip with metadata.
/// Identifiable, Codable, Equatable, Sendable for safe storage and transfer.
struct ClipboardItem: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let text: String
    let copiedAt: Date
    let isPinned: Bool

    init(
        id: UUID = UUID(),
        text: String,
        copiedAt: Date = Date(),
        isPinned: Bool = false
    ) {
        self.id = id
        self.text = ClipboardItem.sanitize(text)
        self.copiedAt = copiedAt
        self.isPinned = isPinned
    }

    enum CodingKeys: String, CodingKey {
        case id, text, copiedAt, isPinned
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        text = try container.decode(String.self, forKey: .text)
        copiedAt = try container.decode(Date.self, forKey: .copiedAt)
        isPinned = try container.decodeIfPresent(Bool.self, forKey: .isPinned) ?? false
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