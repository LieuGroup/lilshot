import XCTest
@testable import LilshotCore

final class LilshotCoreTests: XCTestCase {
    func testPackageLoads() {
        let window = WindowInfo(
            id: 1,
            appName: "Test",
            title: "Hello",
            width: 100,
            height: 100,
            isOnScreen: true
        )
        XCTAssertEqual(window.appName, "Test")
    }
}
