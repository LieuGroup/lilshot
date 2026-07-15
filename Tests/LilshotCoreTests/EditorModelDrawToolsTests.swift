import CoreGraphics
import XCTest
@testable import LilshotCore

final class EditorModelDrawToolsTests: XCTestCase {
    func testDefaultTextFontSizeIsFivePercentOfCanvasHeight() {
        XCTAssertEqual(EditorModel.defaultTextFontSize(canvasHeight: 200), 10, accuracy: 0.0001)
        XCTAssertEqual(EditorModel.defaultTextFontSize(canvasHeight: 1000), 50, accuracy: 0.0001)
    }

    func testAddArrowUsesCurrentColorAndStrokeAndRecordsUndo() {
        var model = EditorModel(canvasSize: CGSize(width: 200, height: 100))
        model.color = .red
        model.strokeWidth = 4
        model.addArrow(from: CGPoint(x: 10, y: 10), to: CGPoint(x: 80, y: 40))
        XCTAssertEqual(
            model.annotations,
            [
                .arrow(
                    from: CGPoint(x: 10, y: 10),
                    to: CGPoint(x: 80, y: 40),
                    color: .red,
                    strokeWidth: 4
                ),
            ]
        )
        XCTAssertTrue(model.canUndo)
        model.undo()
        XCTAssertTrue(model.annotations.isEmpty)
    }

    func testAddRectNormalizesCornersAndIgnoresTinyDrags() {
        var model = EditorModel(canvasSize: CGSize(width: 200, height: 100))
        model.color = .blue
        model.addRect(from: CGPoint(x: 80, y: 60), to: CGPoint(x: 20, y: 20))
        XCTAssertEqual(
            model.annotations,
            [
                .rect(
                    CGRect(x: 20, y: 20, width: 60, height: 40),
                    color: .blue,
                    strokeWidth: 3
                ),
            ]
        )

        model.addRect(from: CGPoint(x: 10, y: 10), to: CGPoint(x: 10.5, y: 10.5))
        XCTAssertEqual(model.annotations.count, 1)
    }

    func testAddStepNumberAutoIncrementsAndRestoresOnUndo() {
        var model = EditorModel(canvasSize: CGSize(width: 100, height: 100))
        model.color = .amber
        XCTAssertEqual(model.nextStepIndex, 1)

        model.addStepNumber(at: CGPoint(x: 30, y: 40))
        model.addStepNumber(at: CGPoint(x: 50, y: 60))
        XCTAssertEqual(
            model.annotations,
            [
                .stepNumber(center: CGPoint(x: 30, y: 40), index: 1, color: .amber),
                .stepNumber(center: CGPoint(x: 50, y: 60), index: 2, color: .amber),
            ]
        )
        XCTAssertEqual(model.nextStepIndex, 3)

        model.undo()
        XCTAssertEqual(model.nextStepIndex, 2)
        XCTAssertEqual(model.annotations.count, 1)

        model.undo()
        XCTAssertEqual(model.nextStepIndex, 1)
        XCTAssertTrue(model.annotations.isEmpty)
    }

    func testAddTextUsesFivePercentFontAndSkipsBlank() {
        var model = EditorModel(canvasSize: CGSize(width: 200, height: 400))
        model.color = .black
        model.addText(at: CGPoint(x: 12, y: 24), string: "  hello  ")
        XCTAssertEqual(
            model.annotations,
            [
                .text(
                    origin: CGPoint(x: 12, y: 24),
                    string: "hello",
                    fontSize: 20,
                    color: .black
                ),
            ]
        )

        model.addText(at: CGPoint(x: 0, y: 0), string: "   ")
        XCTAssertEqual(model.annotations.count, 1)
    }

    func testAddTextRedoRestoresAnnotationAndStepCounterIndependently() {
        var model = EditorModel(canvasSize: CGSize(width: 100, height: 100))
        model.addStepNumber(at: CGPoint(x: 10, y: 10))
        model.addText(at: CGPoint(x: 5, y: 5), string: "note")
        model.undo()
        XCTAssertEqual(model.annotations.count, 1)
        XCTAssertEqual(model.nextStepIndex, 2)
        model.redo()
        XCTAssertEqual(model.annotations.count, 2)
        if case let .text(_, string, fontSize, _) = model.annotations[1] {
            XCTAssertEqual(string, "note")
            XCTAssertEqual(fontSize, 5, accuracy: 0.0001)
        } else {
            XCTFail("expected text annotation")
        }
    }
}
