import XCTest
@testable import LilshotCore

final class WindowNoiseFilterTests: XCTestCase {
    private func window(
        id: UInt32,
        app: String,
        title: String = "",
        width: Int = 800,
        height: Int = 600,
        onScreen: Bool = true
    ) -> WindowInfo {
        WindowInfo(
            id: id,
            appName: app,
            title: title,
            width: width,
            height: height,
            isOnScreen: onScreen
        )
    }

    func testDropsWindowsSmallerThan40Points() {
        let windows = [
            window(id: 1, app: "Safari", width: 800, height: 600),
            window(id: 2, app: "Agent", width: 39, height: 100),
            window(id: 3, app: "Overlay", width: 100, height: 39),
            window(id: 4, app: "Tiny", width: 40, height: 40),
        ]

        let filtered = WindowNoiseFilter.apply(to: windows)

        XCTAssertEqual(filtered.map(\.id), [1, 4])
    }

    func testDropsWindowsWithEmptyAppName() {
        let windows = [
            window(id: 1, app: "Safari"),
            window(id: 2, app: ""),
            window(id: 3, app: "Notes"),
        ]

        let filtered = WindowNoiseFilter.apply(to: windows)

        XCTAssertEqual(filtered.map(\.id), [3, 1])
    }

    func testSortsOffscreenFirstThenAppNameThenID() {
        let windows = [
            window(id: 30, app: "Safari", onScreen: true),
            window(id: 10, app: "Notes", onScreen: false),
            window(id: 20, app: "Notes", onScreen: false),
            window(id: 5, app: "Chrome", onScreen: true),
            window(id: 15, app: "Chrome", onScreen: false),
        ]

        let filtered = WindowNoiseFilter.apply(to: windows)

        XCTAssertEqual(filtered.map(\.id), [15, 10, 20, 5, 30])
    }

    func testPreservesEmptyTitleWindows() {
        let windows = [window(id: 1, app: "Finder", title: "")]

        let filtered = WindowNoiseFilter.apply(to: windows)

        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered[0].title, "")
    }
}
