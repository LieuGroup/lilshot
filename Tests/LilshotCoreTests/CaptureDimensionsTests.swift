import CoreGraphics
import XCTest
@testable import LilshotCore

final class CaptureDimensionsTests: XCTestCase {
    func testNativeCaptureOn1xDisplay() {
        let size = CaptureDimensions.pixelSize(
            pointSize: CGSize(width: 3440, height: 1440),
            pointPixelScale: 1,
            relativeScale: 1
        )
        XCTAssertEqual(size.width, 3440)
        XCTAssertEqual(size.height, 1440)
    }

    func testNativeCaptureOn2xDisplay() {
        let size = CaptureDimensions.pixelSize(
            pointSize: CGSize(width: 1512, height: 982),
            pointPixelScale: 2,
            relativeScale: 1
        )
        XCTAssertEqual(size.width, 3024)
        XCTAssertEqual(size.height, 1964)
    }

    func testHalfPreviewOn1xDisplay() {
        let size = CaptureDimensions.pixelSize(
            pointSize: CGSize(width: 3440, height: 1440),
            pointPixelScale: 1,
            relativeScale: 0.5
        )
        XCTAssertEqual(size.width, 1720)
        XCTAssertEqual(size.height, 720)
    }

    func testHalfPreviewOn2xDisplay() {
        let size = CaptureDimensions.pixelSize(
            pointSize: CGSize(width: 800, height: 600),
            pointPixelScale: 2,
            relativeScale: 0.5
        )
        XCTAssertEqual(size.width, 800)
        XCTAssertEqual(size.height, 600)
    }

    func testRoundsFractionalPixelDimensions() {
        let size = CaptureDimensions.pixelSize(
            pointSize: CGSize(width: 100.4, height: 50.6),
            pointPixelScale: 2,
            relativeScale: 1
        )
        XCTAssertEqual(size.width, 201)
        XCTAssertEqual(size.height, 101)
    }

    func testClampsToMinimumOnePixel() {
        let size = CaptureDimensions.pixelSize(
            pointSize: CGSize(width: 0.1, height: 0.1),
            pointPixelScale: 1,
            relativeScale: 0.1
        )
        XCTAssertEqual(size.width, 1)
        XCTAssertEqual(size.height, 1)
    }
}
