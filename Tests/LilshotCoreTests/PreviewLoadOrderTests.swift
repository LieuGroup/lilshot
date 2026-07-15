import XCTest
@testable import LilshotCore

final class PreviewLoadOrderTests: XCTestCase {
    func testEmptyRowCountReturnsEmpty() {
        XCTAssertEqual(
            PreviewLoadOrder.indices(rowCount: 0, selectedIndex: 0, visibleRange: 0..<0),
            []
        )
    }

    func testSingleRow() {
        XCTAssertEqual(
            PreviewLoadOrder.indices(rowCount: 1, selectedIndex: 0, visibleRange: 0..<1),
            [0]
        )
    }

    func testSelectedFirstThenNeighborsOutwardWithinVisible() {
        // rows 0..<7, selected 3, visible 1..<6 → 3, then 2/4, then 1/5, then outside 0/6
        XCTAssertEqual(
            PreviewLoadOrder.indices(rowCount: 7, selectedIndex: 3, visibleRange: 1..<6),
            [3, 2, 4, 1, 5, 0, 6]
        )
    }

    func testSelectedAtStartExpandsRightThenRest() {
        XCTAssertEqual(
            PreviewLoadOrder.indices(rowCount: 5, selectedIndex: 0, visibleRange: 0..<3),
            [0, 1, 2, 3, 4]
        )
    }

    func testSelectedAtEndExpandsLeftThenRest() {
        XCTAssertEqual(
            PreviewLoadOrder.indices(rowCount: 5, selectedIndex: 4, visibleRange: 2..<5),
            [4, 3, 2, 1, 0]
        )
    }

    func testClampsSelectedIndexIntoBounds() {
        XCTAssertEqual(
            PreviewLoadOrder.indices(rowCount: 3, selectedIndex: 99, visibleRange: 0..<3),
            [2, 1, 0]
        )
        XCTAssertEqual(
            PreviewLoadOrder.indices(rowCount: 3, selectedIndex: -5, visibleRange: 0..<3),
            [0, 1, 2]
        )
    }

    func testClampsVisibleRangeToRowBounds() {
        XCTAssertEqual(
            PreviewLoadOrder.indices(rowCount: 4, selectedIndex: 1, visibleRange: -10..<100),
            [1, 0, 2, 3]
        )
    }

    func testVisibleRangeExcludingSelectedStillStartsWithSelected() {
        // Selected is outside the "visible" band; it still loads first, then visible neighbors.
        XCTAssertEqual(
            PreviewLoadOrder.indices(rowCount: 6, selectedIndex: 0, visibleRange: 2..<5),
            [0, 2, 3, 4, 1, 5]
        )
    }
}
