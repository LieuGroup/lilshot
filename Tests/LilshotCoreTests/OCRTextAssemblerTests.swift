import CoreGraphics
import XCTest
@testable import LilshotCore

final class OCRTextAssemblerTests: XCTestCase {
    func testEmptyInputReturnsEmptyText() {
        XCTAssertEqual(OCRTextAssembler.assemble([]), "")
    }

    func testSingleLineOrdersLeftToRightAndJoinsWithSpaces() {
        let observations = [
            observation("world", x: 0.4, y: 0.7, width: 0.2, height: 0.1),
            observation("Hello", x: 0.1, y: 0.7, width: 0.2, height: 0.1),
        ]

        XCTAssertEqual(OCRTextAssembler.assemble(observations), "Hello world")
    }

    func testOffsetColumnsUseBottomLeftCoordinatesAndVerticalOverlap() {
        let observations = [
            observation("right bottom", x: 0.55, y: 0.48, width: 0.3, height: 0.1),
            observation("left top", x: 0.05, y: 0.80, width: 0.3, height: 0.1),
            observation("left bottom", x: 0.05, y: 0.52, width: 0.3, height: 0.1),
            observation("right top", x: 0.55, y: 0.76, width: 0.3, height: 0.1),
        ]

        XCTAssertEqual(
            OCRTextAssembler.assemble(observations),
            "left top right top\nleft bottom right bottom"
        )
    }

    func testVietnameseDiacriticsPassThroughUnchanged() {
        let observations = [
            observation("Tiếng Việt có dấu", x: 0.1, y: 0.5, width: 0.8, height: 0.1),
        ]

        XCTAssertEqual(OCRTextAssembler.assemble(observations), "Tiếng Việt có dấu")
    }

    func testParagraphGapUsesMedianGroupedLineHeight() {
        let observations = [
            observation("First", x: 0.1, y: 0.80, width: 0.2, height: 0.1),
            observation("Second", x: 0.1, y: 0.64, width: 0.2, height: 0.1),
            observation("Third", x: 0.1, y: 0.20, width: 0.2, height: 0.1),
        ]

        XCTAssertEqual(OCRTextAssembler.assemble(observations), "First\nSecond\n\nThird")
    }

    func testExactlyHalfVerticalOverlapStartsANewLine() {
        let observations = [
            observation("Upper", x: 0.1, y: 0.50, width: 0.2, height: 0.25),
            observation("Lower", x: 0.4, y: 0.375, width: 0.2, height: 0.25),
        ]

        XCTAssertEqual(OCRTextAssembler.assemble(observations), "Upper\nLower")
    }

    private func observation(
        _ text: String,
        x: CGFloat,
        y: CGFloat,
        width: CGFloat,
        height: CGFloat
    ) -> (String, CGRect) {
        (text, CGRect(x: x, y: y, width: width, height: height))
    }
}
