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

    func testLoadsFromPersistenceOnInit() {
        let persistence = MockLastCapturePersistence()
        persistence.set(99, forKey: LastCapturePersistenceKey.windowID)
        persistence.set("Mail", forKey: LastCapturePersistenceKey.appName)

        let store = LastCaptureStore(persistence: persistence)
        XCTAssertEqual(store.current?.windowID, 99)
        XCTAssertEqual(store.current?.appName, "Mail")
    }

    func testIgnoresIncompletePersistence() {
        let persistence = MockLastCapturePersistence()
        persistence.set(12, forKey: LastCapturePersistenceKey.windowID)
        // missing appName
        let store = LastCaptureStore(persistence: persistence)
        XCTAssertNil(store.current)
    }

    func testRememberWritesToPersistence() {
        let persistence = MockLastCapturePersistence()
        var store = LastCaptureStore(persistence: persistence)
        store.remember(windowID: 5, appName: "Xcode")

        XCTAssertEqual(persistence.integer(forKey: LastCapturePersistenceKey.windowID), 5)
        XCTAssertEqual(persistence.string(forKey: LastCapturePersistenceKey.appName), "Xcode")
    }

    func testClearRemovesPersistence() {
        let persistence = MockLastCapturePersistence()
        var store = LastCaptureStore(persistence: persistence)
        store.remember(windowID: 3, appName: "Notes")
        store.clear()

        XCTAssertNil(persistence.integer(forKey: LastCapturePersistenceKey.windowID))
        XCTAssertNil(persistence.string(forKey: LastCapturePersistenceKey.appName))
        XCTAssertNil(store.current)
    }

    func testExplicitCurrentOverridesPersistenceLoad() {
        let persistence = MockLastCapturePersistence()
        persistence.set(1, forKey: LastCapturePersistenceKey.windowID)
        persistence.set("Old", forKey: LastCapturePersistenceKey.appName)

        let store = LastCaptureStore(
            current: LastCapture(windowID: 2, appName: "New"),
            persistence: persistence
        )
        XCTAssertEqual(store.current?.windowID, 2)
        XCTAssertEqual(store.current?.appName, "New")
    }
}

/// In-memory get/set seam for LastCaptureStore tests.
final class MockLastCapturePersistence: LastCapturePersisting, @unchecked Sendable {
    private var ints: [String: Int] = [:]
    private var strings: [String: String] = [:]

    func integer(forKey key: String) -> Int? { ints[key] }
    func string(forKey key: String) -> String? { strings[key] }

    func set(_ value: Int?, forKey key: String) {
        if let value {
            ints[key] = value
        } else {
            ints.removeValue(forKey: key)
        }
    }

    func set(_ value: String?, forKey key: String) {
        if let value {
            strings[key] = value
        } else {
            strings.removeValue(forKey: key)
        }
    }
}
