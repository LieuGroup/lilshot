import CoreGraphics
import XCTest
@testable import LilshotCore

final class RegionGeometryTests: XCTestCase {
    func testNormalizedRectOrdersCornersRegardlessOfDragDirection() {
        let rect = RegionGeometry.normalizedRect(
            from: CGPoint(x: 100, y: 50),
            to: CGPoint(x: 20, y: 200)
        )
        XCTAssertEqual(rect.origin.x, 20)
        XCTAssertEqual(rect.origin.y, 50)
        XCTAssertEqual(rect.width, 80)
        XCTAssertEqual(rect.height, 150)
    }

    func testNormalizedRectZeroSizeWhenPointsIdentical() {
        let p = CGPoint(x: 40, y: 40)
        let rect = RegionGeometry.normalizedRect(from: p, to: p)
        XCTAssertEqual(rect.origin, p)
        XCTAssertEqual(rect.width, 0)
        XCTAssertEqual(rect.height, 0)
    }

    func testClampIntersectsWithDisplayBounds() {
        let bounds = CGRect(x: 0, y: 0, width: 100, height: 80)
        let clamped = RegionGeometry.clamp(
            CGRect(x: -10, y: 60, width: 50, height: 40),
            to: bounds
        )
        XCTAssertEqual(clamped, CGRect(x: 0, y: 60, width: 40, height: 20))
    }

    func testClampOutsideBoundsYieldsEmptyRect() {
        let bounds = CGRect(x: 0, y: 0, width: 100, height: 80)
        let clamped = RegionGeometry.clamp(
            CGRect(x: 200, y: 200, width: 10, height: 10),
            to: bounds
        )
        XCTAssertTrue(clamped.isEmpty)
    }

    func testAppKitToScreenCaptureKitFlipsYFromBottomLeft() {
        // AppKit local: origin bottom-left. Display height 100.
        // Rect at bottom-left of display → SCK origin at top of that rect.
        let appKit = CGRect(x: 10, y: 20, width: 30, height: 40)
        let sck = RegionGeometry.appKitRectToScreenCaptureKit(
            appKit,
            displayHeight: 100
        )
        XCTAssertEqual(sck.origin.x, 10)
        XCTAssertEqual(sck.origin.y, 40) // 100 - (20 + 40)
        XCTAssertEqual(sck.width, 30)
        XCTAssertEqual(sck.height, 40)
    }

    func testPixelRectScalesPointRectForRetinaCrop() {
        let points = CGRect(x: 10, y: 20, width: 50, height: 40)
        let pixels = RegionGeometry.pixelRect(from: points, scale: 2)
        XCTAssertEqual(pixels, CGRect(x: 20, y: 40, width: 100, height: 80))
    }
}
