import XCTest
@testable import LilshotCore

final class WindowNoiseFilterTests: XCTestCase {
    private func window(
        id: UInt32,
        app: String,
        title: String = "",
        width: Int = 800,
        height: Int = 600,
        onScreen: Bool = true,
        layer: Int = 0,
        ownerIsRegularApp: Bool = true
    ) -> WindowInfo {
        WindowInfo(
            id: id,
            appName: app,
            title: title,
            width: width,
            height: height,
            isOnScreen: onScreen,
            layer: layer,
            ownerIsRegularApp: ownerIsRegularApp
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
            window(id: 30, app: "Safari", title: "Home", onScreen: true),
            window(id: 10, app: "Notes", title: "A", onScreen: false),
            window(id: 20, app: "Notes", title: "B", onScreen: false),
            window(id: 5, app: "Chrome", title: "Tab", onScreen: true),
            window(id: 15, app: "Chrome", title: "Other", onScreen: false),
        ]

        let filtered = WindowNoiseFilter.apply(to: windows)

        XCTAssertEqual(filtered.map(\.id), [15, 10, 20, 5, 30])
    }

    func testKeepsEmptyTitleWindowsWhenOnScreen() {
        let windows = [window(id: 1, app: "Finder", title: "", onScreen: true)]

        let filtered = WindowNoiseFilter.apply(to: windows)

        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered[0].title, "")
    }

    func testDropsEmptyTitleWindowsWhenOffScreen() {
        let windows = [
            window(id: 1, app: "Claude", title: "", width: 3440, height: 1440, onScreen: false),
            window(id: 2, app: "Claude", title: "Chat", onScreen: false),
            window(id: 3, app: "Claude", title: "", onScreen: true),
        ]

        let filtered = WindowNoiseFilter.apply(to: windows)

        XCTAssertEqual(filtered.map(\.id), [2, 3])
    }

    func testDropsNonZeroLayerWindows() {
        let windows = [
            window(id: 1, app: "Safari", layer: 0),
            window(id: 2, app: "Safari", layer: 1),
            window(id: 3, app: "Notes", layer: 3),
            window(id: 4, app: "Notes", layer: 0),
        ]

        let filtered = WindowNoiseFilter.apply(to: windows)

        XCTAssertEqual(filtered.map(\.id), [4, 1])
    }

    func testDropsNonRegularOwnerApps() {
        let windows = [
            window(id: 1, app: "Claude", ownerIsRegularApp: true),
            window(id: 2, app: "CursorUIViewService", ownerIsRegularApp: false),
            window(id: 3, app: "Open and Save Panel Service", ownerIsRegularApp: false),
            window(id: 4, app: "Notes", ownerIsRegularApp: true),
        ]

        let filtered = WindowNoiseFilter.apply(to: windows)

        XCTAssertEqual(filtered.map(\.id), [1, 4])
    }
}
