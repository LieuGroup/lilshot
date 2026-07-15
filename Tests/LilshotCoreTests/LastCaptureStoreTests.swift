import XCTest
@testable import LilshotCore

final class LastCaptureStoreTests: XCTestCase {
    func testStartsEmpty() {
        let store = LastCaptureStore()
        XCTAssertNil(store.current)
    }

    func testRememberSetsWindowIDAndAppName() {
        var store = LastCaptureStore()
        store.remember(windowID: 42, appName: "Safari")
        XCTAssertEqual(store.current?.windowID, 42)
        XCTAssertEqual(store.current?.appName, "Safari")
    }

    func testRememberOverwritesPrevious() {
        var store = LastCaptureStore()
        store.remember(windowID: 1, appName: "A")
        store.remember(windowID: 2, appName: "B")
        XCTAssertEqual(store.current?.windowID, 2)
        XCTAssertEqual(store.current?.appName, "B")
    }

    func testClearResetsToEmpty() {
        var store = LastCaptureStore()
        store.remember(windowID: 7, appName: "Notes")
        store.clear()
        XCTAssertNil(store.current)
    }
}
