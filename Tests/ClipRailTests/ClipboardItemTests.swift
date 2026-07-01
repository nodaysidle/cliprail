import XCTest
@testable import ClipRail

final class ClipboardItemTests: XCTestCase {

    func testSanitizeRemovesControlCharacters() {
        let raw = "Hello\u{00}World\u{01}Test"
        let sanitized = ClipboardItem.sanitize(raw)
        XCTAssertEqual(sanitized, "HelloWorldTest")
    }

    func testSanitizePreservesNewlineAndTab() {
        let raw = "Line1\nLine2\tIndented"
        let sanitized = ClipboardItem.sanitize(raw)
        XCTAssertEqual(sanitized, "Line1\nLine2\tIndented")
    }

    func testSanitizeTrimsWhitespace() {
        let raw = "   hello   \n"
        let sanitized = ClipboardItem.sanitize(raw)
        XCTAssertEqual(sanitized, "hello")
    }

    func testSanitizeEmptyString() {
        let sanitized = ClipboardItem.sanitize("")
        XCTAssertEqual(sanitized, "")
    }

    func testSanitizeOnlyControlCharacters() {
        let sanitized = ClipboardItem.sanitize("\u{00}\u{01}\u{02}")
        XCTAssertEqual(sanitized, "")
    }

    func testIsValid() {
        XCTAssertTrue(ClipboardItem.isValid("hello"))
        XCTAssertFalse(ClipboardItem.isValid(""))
        XCTAssertFalse(ClipboardItem.isValid("   "))
        XCTAssertFalse(ClipboardItem.isValid("\u{00}\u{01}"))
    }

    func testPreviewShortText() {
        let item = ClipboardItem(text: "short text")
        XCTAssertEqual(item.preview(), "short text")
    }

    func testPreviewTruncatesLongText() {
        let long = String(repeating: "a", count: 200)
        let item = ClipboardItem(text: long)
        let preview = item.preview(maxLength: 120)
        XCTAssertEqual(preview.count, 121) // 120 + "…"
        XCTAssertTrue(preview.hasSuffix("…"))
    }

    func testPreviewReplacesNewlines() {
        let item = ClipboardItem(text: "line1\nline2\nline3")
        let preview = item.preview()
        XCTAssertTrue(preview.contains("↵"))
        XCTAssertFalse(preview.contains("\n"))
    }

    func testCodableRoundtrip() throws {
        let item = ClipboardItem(text: "test text", isPinned: true)
        let data = try JSONEncoder().encode(item)
        let decoded = try JSONDecoder().decode(ClipboardItem.self, from: data)
        XCTAssertEqual(decoded.id, item.id)
        XCTAssertEqual(decoded.text, item.text)
        XCTAssertTrue(decoded.isPinned)
        XCTAssertEqual(decoded.copiedAt.timeIntervalSinceReferenceDate,
                       item.copiedAt.timeIntervalSinceReferenceDate,
                       accuracy: 0.001)
    }

    func testCodableDefaultsMissingPinField() throws {
        let json = """
        {"id":"\(UUID().uuidString)","text":"legacy","copiedAt":0}
        """
        let data = Data(json.utf8)
        let decoded = try JSONDecoder().decode(ClipboardItem.self, from: data)
        XCTAssertFalse(decoded.isPinned)
    }

    func testEquatable() {
        let a = ClipboardItem(id: UUID(), text: "same", copiedAt: Date())
        let b = ClipboardItem(id: UUID(), text: "same", copiedAt: Date())
        XCTAssertEqual(a.text, b.text)
        XCTAssertNotEqual(a.id, b.id)
    }
}
