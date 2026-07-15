import XCTest
@testable import LilshotCore

final class PickerViewModelTests: XCTestCase {
    private func window(
        id: UInt32,
        app: String = "App",
        title: String = "Title",
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

    func testInitAppliesNoiseFilterAndSelectsFirst() {
        let tiny = window(id: 1, width: 10, height: 10)
        let chrome = window(id: 2, app: "Chrome", title: "Docs")
        let notes = window(id: 3, app: "Notes", title: "Todo")

        var model = PickerViewModel(windows: [tiny, chrome, notes])

        XCTAssertEqual(model.rows.map(\.id), [2, 3])
        XCTAssertEqual(model.selectedIndex, 0)
        XCTAssertEqual(model.selectedWindow?.id, 2)
        XCTAssertEqual(model.query, "")
    }

    func testEmptyWindowsHasNoSelection() {
        let model = PickerViewModel(windows: [])
        XCTAssertTrue(model.rows.isEmpty)
        XCTAssertEqual(model.selectedIndex, 0)
        XCTAssertNil(model.selectedWindow)
    }

    func testEmptyQueryKeepsNoiseFilteredOffscreenFirstOrder() {
        let onScreen = window(id: 1, app: "Chrome", onScreen: true)
        let offScreen = window(id: 2, app: "Notes", onScreen: false)

        var model = PickerViewModel(windows: [onScreen, offScreen])
        model.setQuery("")

        XCTAssertEqual(model.rows.map(\.id), [2, 1])
        XCTAssertEqual(model.selectedIndex, 0)
    }

    func testSetQueryRanksAndResetsSelectionToBestMatch() {
        let chrome = window(id: 1, app: "Google Chrome", title: "Inbox")
        let notes = window(id: 2, app: "Notes", title: "chrome tips")

        var model = PickerViewModel(windows: [notes, chrome])
        model.setQuery("chrome")

        XCTAssertEqual(model.rows.first?.id, 1)
        XCTAssertEqual(model.selectedIndex, 0)
        XCTAssertEqual(model.selectedWindow?.appName, "Google Chrome")
        XCTAssertEqual(model.query, "chrome")
    }

    func testSetQueryResetsSelectionWhenSelectedWindowDropsOut() {
        let a = window(id: 10, app: "Alpha", title: "One")
        let b = window(id: 20, app: "Beta", title: "Two")
        let c = window(id: 30, app: "Alpha", title: "Three")

        var model = PickerViewModel(windows: [a, b, c])
        // Noise filter sorts by app name, then id: Alpha/10, Alpha/30, Beta/20.
        XCTAssertEqual(model.rows.map(\.id), [10, 30, 20])
        model.moveSelection(2)
        XCTAssertEqual(model.selectedWindow?.id, 20)

        model.setQuery("alpha")
        XCTAssertEqual(model.rows.map(\.id), [10, 30])
        XCTAssertNil(model.rows.first(where: { $0.id == 20 }))
        XCTAssertEqual(model.selectedIndex, 0)
        XCTAssertEqual(model.selectedWindow?.id, 10)
    }

    func testSetQueryKeepsSelectionWhenWindowSurvivesRerank() {
        let a = window(id: 10, app: "Alpha", title: "Report")
        let b = window(id: 20, app: "Beta", title: "Alpha notes")

        var model = PickerViewModel(windows: [a, b])
        model.moveSelection(1)
        XCTAssertEqual(model.selectedWindow?.id, 20)

        model.setQuery("alpha")
        XCTAssertTrue(model.rows.contains(where: { $0.id == 20 }))
        XCTAssertEqual(model.selectedWindow?.id, 20)
    }

    func testMoveSelectionWrapsAtEnds() {
        let windows = [
            window(id: 1, app: "A"),
            window(id: 2, app: "B"),
            window(id: 3, app: "C"),
        ]
        var model = PickerViewModel(windows: windows)

        model.moveSelection(-1)
        XCTAssertEqual(model.selectedIndex, 2)
        XCTAssertEqual(model.selectedWindow?.id, 3)

        model.moveSelection(1)
        XCTAssertEqual(model.selectedIndex, 0)
        XCTAssertEqual(model.selectedWindow?.id, 1)
    }

    func testMoveSelectionNoOpWhenEmpty() {
        var model = PickerViewModel(windows: [])
        model.moveSelection(1)
        model.moveSelection(-1)
        XCTAssertEqual(model.selectedIndex, 0)
        XCTAssertNil(model.selectedWindow)
    }

    func testNoMatchesClearsSelection() {
        var model = PickerViewModel(windows: [window(id: 1, app: "Chrome")])
        model.setQuery("zzzz-no-match")
        XCTAssertTrue(model.rows.isEmpty)
        XCTAssertNil(model.selectedWindow)
    }
}
