import CoreGraphics
import XCTest
@testable import LilshotCore

final class AnnotationHitTestingTests: XCTestCase {
    func testDistanceToSegmentIsZeroOnLineAndPositiveOffIt() {
        let a = CGPoint(x: 0, y: 0)
        let b = CGPoint(x: 100, y: 0)
        XCTAssertEqual(
            AnnotationHitTesting.distanceToSegment(CGPoint(x: 50, y: 0), from: a, to: b),
            0,
            accuracy: 0.0001
        )
        XCTAssertEqual(
            AnnotationHitTesting.distanceToSegment(CGPoint(x: 50, y: 10), from: a, to: b),
            10,
            accuracy: 0.0001
        )
        // Past the end → distance to nearest endpoint
        XCTAssertEqual(
            AnnotationHitTesting.distanceToSegment(CGPoint(x: 120, y: 0), from: a, to: b),
            20,
            accuracy: 0.0001
        )
    }

    func testDistanceToRectEdgeIsZeroOnStrokeAndInteriorIsFarther() {
        let rect = CGRect(x: 10, y: 20, width: 80, height: 40)
        XCTAssertEqual(
            AnnotationHitTesting.distanceToRectEdge(CGPoint(x: 10, y: 40), rect: rect),
            0,
            accuracy: 0.0001
        )
        XCTAssertEqual(
            AnnotationHitTesting.distanceToRectEdge(CGPoint(x: 50, y: 40), rect: rect),
            20,
            accuracy: 0.0001
        )
        XCTAssertEqual(
            AnnotationHitTesting.distanceToRectEdge(CGPoint(x: 0, y: 40), rect: rect),
            10,
            accuracy: 0.0001
        )
    }

    func testArrowHitUsesLineProximity() {
        let arrow = Annotation.arrow(
            from: CGPoint(x: 0, y: 0),
            to: CGPoint(x: 100, y: 0),
            color: .red,
            strokeWidth: 3
        )
        XCTAssertTrue(
            AnnotationHitTesting.contains(arrow, point: CGPoint(x: 50, y: 4), tolerance: 8)
        )
        XCTAssertFalse(
            AnnotationHitTesting.contains(arrow, point: CGPoint(x: 50, y: 20), tolerance: 8)
        )
    }

    func testRectHitUsesEdgeProximityNotFill() {
        let box = Annotation.rect(
            CGRect(x: 10, y: 10, width: 80, height: 60),
            color: .blue,
            strokeWidth: 2
        )
        XCTAssertTrue(
            AnnotationHitTesting.contains(box, point: CGPoint(x: 10, y: 40), tolerance: 8)
        )
        XCTAssertFalse(
            AnnotationHitTesting.contains(box, point: CGPoint(x: 50, y: 40), tolerance: 8)
        )
    }

    func testBlurHitUsesFilledRect() {
        let blur = Annotation.blur(CGRect(x: 20, y: 30, width: 40, height: 20))
        XCTAssertTrue(
            AnnotationHitTesting.contains(blur, point: CGPoint(x: 30, y: 35), tolerance: 8)
        )
        XCTAssertFalse(
            AnnotationHitTesting.contains(blur, point: CGPoint(x: 5, y: 5), tolerance: 8)
        )
    }

    func testStepNumberHitUsesCircleBounds() {
        let step = Annotation.stepNumber(
            center: CGPoint(x: 50, y: 50),
            index: 1,
            color: .amber
        )
        XCTAssertTrue(
            AnnotationHitTesting.contains(step, point: CGPoint(x: 55, y: 50), tolerance: 8)
        )
        XCTAssertFalse(
            AnnotationHitTesting.contains(step, point: CGPoint(x: 80, y: 50), tolerance: 8)
        )
    }

    func testTextHitUsesEstimatedStringBounds() {
        let text = Annotation.text(
            origin: CGPoint(x: 10, y: 40),
            string: "Hi",
            fontSize: 20,
            color: .black
        )
        let bounds = AnnotationHitTesting.selectionBounds(text)
        XCTAssertTrue(bounds.contains(CGPoint(x: 15, y: 35)))
        XCTAssertTrue(AnnotationHitTesting.contains(text, point: CGPoint(x: 15, y: 35), tolerance: 0))
        XCTAssertFalse(
            AnnotationHitTesting.contains(text, point: CGPoint(x: 200, y: 200), tolerance: 0)
        )
    }

    func testHitIndexPrefersTopmostAnnotation() {
        let annotations: [Annotation] = [
            .rect(CGRect(x: 0, y: 0, width: 100, height: 100), color: .red, strokeWidth: 2),
            .blur(CGRect(x: 40, y: 40, width: 20, height: 20)),
        ]
        // Interior of blur (topmost) wins over rect edge miss / blur fill
        XCTAssertEqual(
            AnnotationHitTesting.hitIndex(at: CGPoint(x: 50, y: 50), in: annotations),
            1
        )
        // Left edge of rect, outside blur
        XCTAssertEqual(
            AnnotationHitTesting.hitIndex(at: CGPoint(x: 0, y: 50), in: annotations),
            0
        )
        XCTAssertNil(
            AnnotationHitTesting.hitIndex(at: CGPoint(x: 200, y: 200), in: annotations)
        )
    }

    func testPixellateCellSizeIsOneAndHalfPercentWithMinEight() {
        XCTAssertEqual(
            AnnotationHitTesting.pixellateCellSize(imageSize: CGSize(width: 1000, height: 500)),
            15,
            accuracy: 0.0001
        )
        XCTAssertEqual(
            AnnotationHitTesting.pixellateCellSize(imageSize: CGSize(width: 200, height: 100)),
            8,
            accuracy: 0.0001
        )
    }
}
