import XCTest
@testable import LilshotCore

final class HotkeyFailureFormattingTests: XCTestCase {
    func testEmptyFailuresYieldEmptyString() {
        XCTAssertEqual(HotkeyFailureFormatting.summary(labelsAndStatuses: []), "")
    }

    func testFormatsSingleFailure() {
        let text = HotkeyFailureFormatting.summary(
            labelsAndStatuses: [("⌥⇧S", -987)]
        )
        XCTAssertEqual(text, "hotkey registration partial failure: ⌥⇧S (OSStatus -987)")
    }

    func testJoinsMultipleFailures() {
        let text = HotkeyFailureFormatting.summary(
            labelsAndStatuses: [("⌥⇧S", 1), ("⌥⇧A", 2)]
        )
        XCTAssertEqual(
            text,
            "hotkey registration partial failure: ⌥⇧S (OSStatus 1), ⌥⇧A (OSStatus 2)"
        )
    }
}
