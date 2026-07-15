import CoreGraphics
import XCTest
@testable import LilshotCore

final class EditorGeometryTests: XCTestCase {
    func testFitScalePicksLimitingAxis() {
        let scale = EditorGeometry.fitScale(
            imageSize: CGSize(width: 200, height: 100),
            viewSize: CGSize(width: 100, height: 100)
        )
        XCTAssertEqual(scale, 0.5, accuracy: 0.0001)
    }

    func testFittedImageRectCentersScaledImage() {
        let fitted = EditorGeometry.fittedImageRect(
            imageSize: CGSize(width: 200, height: 100),
            in: CGSize(width: 100, height: 100)
        )
        XCTAssertEqual(fitted.origin.x, 0, accuracy: 0.0001)
        XCTAssertEqual(fitted.origin.y, 25, accuracy: 0.0001)
        XCTAssertEqual(fitted.width, 100, accuracy: 0.0001)
        XCTAssertEqual(fitted.height, 50, accuracy: 0.0001)
    }

    func testViewToImagePointUsesFittedRect() {
        let image = EditorGeometry.imagePoint(
            fromView: CGPoint(x: 50, y: 50),
            imageSize: CGSize(width: 200, height: 100),
            viewSize: CGSize(width: 100, height: 100)
        )
        // fitted rect: (0, 25, 100, 50) → scale 0.5
        // view (50, 50) → image ((50-0)/0.5, (50-25)/0.5) = (100, 50)
        XCTAssertEqual(image.x, 100, accuracy: 0.0001)
        XCTAssertEqual(image.y, 50, accuracy: 0.0001)
    }

    func testImageToViewPointRoundTrips() {
        let imageSize = CGSize(width: 400, height: 200)
        let viewSize = CGSize(width: 200, height: 200)
        let original = CGPoint(x: 80, y: 40)
        let view = EditorGeometry.viewPoint(
            fromImage: original,
            imageSize: imageSize,
            viewSize: viewSize
        )
        let back = EditorGeometry.imagePoint(
            fromView: view,
            imageSize: imageSize,
            viewSize: viewSize
        )
        XCTAssertEqual(back.x, original.x, accuracy: 0.0001)
        XCTAssertEqual(back.y, original.y, accuracy: 0.0001)
    }

    func testImageRectMapsThroughFittedScale() {
        let imageRect = CGRect(x: 40, y: 20, width: 80, height: 40)
        let viewRect = EditorGeometry.viewRect(
            fromImage: imageRect,
            imageSize: CGSize(width: 200, height: 100),
            viewSize: CGSize(width: 100, height: 100)
        )
        // scale 0.5, origin (0, 25)
        XCTAssertEqual(viewRect.origin.x, 20, accuracy: 0.0001)
        XCTAssertEqual(viewRect.origin.y, 35, accuracy: 0.0001)
        XCTAssertEqual(viewRect.width, 40, accuracy: 0.0001)
        XCTAssertEqual(viewRect.height, 20, accuracy: 0.0001)
    }

    func testArrowheadPointsAreSymmetricAboutShaft() {
        let tips = EditorGeometry.arrowheadPoints(
            from: CGPoint(x: 0, y: 0),
            to: CGPoint(x: 100, y: 0),
            length: 10,
            width: 8
        )
        // Shaft along +X; tip at (100,0); base center at (90,0)
        XCTAssertEqual(tips.left.x, 90, accuracy: 0.0001)
        XCTAssertEqual(tips.right.x, 90, accuracy: 0.0001)
        XCTAssertEqual(tips.left.y, 4, accuracy: 0.0001)
        XCTAssertEqual(tips.right.y, -4, accuracy: 0.0001)
    }

    func testArrowheadDegenerateWhenShaftTooShort() {
        let tips = EditorGeometry.arrowheadPoints(
            from: CGPoint(x: 10, y: 10),
            to: CGPoint(x: 10.5, y: 10),
            length: 10,
            width: 8
        )
        XCTAssertEqual(tips.left, CGPoint(x: 10.5, y: 10))
        XCTAssertEqual(tips.right, CGPoint(x: 10.5, y: 10))
    }

    func testClampCropRectReusesRegionGeometry() {
        let clamped = EditorGeometry.clampCrop(
            CGRect(x: -5, y: 10, width: 50, height: 100),
            to: CGSize(width: 80, height: 60)
        )
        XCTAssertEqual(clamped, CGRect(x: 0, y: 10, width: 45, height: 50))
    }
}
