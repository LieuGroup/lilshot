import XCTest
@testable import LilshotCore

final class CaptureQueryResolverTests: XCTestCase {
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

    func testAllDigitsQueryResolvesExactWindowID() throws {
        let windows = [
            window(id: 42, app: "Safari"),
            window(id: 99, app: "Notes"),
        ]

        let result = try CaptureQueryResolver.resolve(query: "42", in: windows)

        guard case .matched(let window) = result else {
            return XCTFail("expected matched")
        }
        XCTAssertEqual(window.id, 42)
    }

    func testAllDigitsQueryThrowsWhenWindowMissing() {
        let windows = [window(id: 1, app: "Safari")]

        XCTAssertThrowsError(try CaptureQueryResolver.resolve(query: "999", in: windows)) { error in
            guard case CaptureQueryResolver.Error.windowNotFound(let id) = error else {
                return XCTFail("expected windowNotFound")
            }
            XCTAssertEqual(id, 999)
        }
    }

    func testFuzzyQueryReturnsClearWinner() throws {
        let windows = [
            window(id: 1, app: "Safari"),
            window(id: 2, app: "Google Chrome"),
            window(id: 3, app: "Notes"),
        ]

        let result = try CaptureQueryResolver.resolve(query: "chr", in: windows)

        guard case .matched(let window) = result else {
            return XCTFail("expected matched")
        }
        XCTAssertEqual(window.id, 2)
    }

    func testAmbiguousQueryReturnsRankedCandidates() throws {
        // Equal-length cross-app targets → equal coverage → score tie → ambiguous.
        let windows = [
            window(id: 10, app: "Code One"),
            window(id: 5, app: "Code Two"),
            window(id: 30, app: "Safari"),
        ]

        let result = try CaptureQueryResolver.resolve(query: "code", in: windows)

        guard case .ambiguous(let candidates) = result else {
            return XCTFail("expected ambiguous")
        }
        XCTAssertEqual(candidates.map(\.window.id), [5, 10])
        XCTAssertEqual(candidates[0].score, candidates[1].score)
    }

    func testSameAppTiePrefersNonEmptyTitle() throws {
        let windows = [
            window(id: 1, app: "Notes", title: "", width: 500, height: 500),
            window(id: 2, app: "Notes", title: "Shopping list", width: 500, height: 500),
        ]

        let result = try CaptureQueryResolver.resolve(query: "notes", in: windows)

        guard case .matched(let window) = result else {
            return XCTFail("expected matched")
        }
        XCTAssertEqual(window.id, 2)
    }

    func testSameAppTiePrefersLargerArea() throws {
        let windows = [
            window(id: 1, app: "Notes", title: "A", width: 400, height: 300),
            window(id: 2, app: "Notes", title: "B", width: 1200, height: 800),
        ]

        let result = try CaptureQueryResolver.resolve(query: "notes", in: windows)

        guard case .matched(let window) = result else {
            return XCTFail("expected matched")
        }
        XCTAssertEqual(window.id, 2)
    }

    func testSameAppTiePrefersLowerIDWhenEqual() throws {
        let windows = [
            window(id: 20, app: "Notes", title: "A", width: 800, height: 600),
            window(id: 10, app: "Notes", title: "B", width: 800, height: 600),
        ]

        let result = try CaptureQueryResolver.resolve(query: "notes", in: windows)

        guard case .matched(let window) = result else {
            return XCTFail("expected matched")
        }
        XCTAssertEqual(window.id, 10)
    }

    func testCrossAppTieRemainsAmbiguous() throws {
        // Equal-length cross-app targets keep scores tied; same-app preference must not apply.
        let windows = [
            window(id: 10, app: "Code One", title: "main.swift"),
            window(id: 5, app: "Code Two", title: "main.swift"),
        ]

        let result = try CaptureQueryResolver.resolve(query: "code", in: windows)

        guard case .ambiguous(let candidates) = result else {
            return XCTFail("expected ambiguous")
        }
        XCTAssertEqual(Set(candidates.map(\.window.appName)), Set(["Code One", "Code Two"]))
        XCTAssertEqual(candidates[0].score, candidates[1].score)
    }

    func testSingleMatchIsClearWinner() throws {
        let windows = [
            window(id: 1, app: "Notes", title: "Grok chat"),
            window(id: 2, app: "Safari", title: "Apple"),
        ]

        let result = try CaptureQueryResolver.resolve(query: "grok", in: windows)

        guard case .matched(let window) = result else {
            return XCTFail("expected matched")
        }
        XCTAssertEqual(window.id, 1)
    }

    func testNoFuzzyMatchesThrows() {
        let windows = [window(id: 1, app: "Safari")]

        XCTAssertThrowsError(try CaptureQueryResolver.resolve(query: "zzzz", in: windows)) { error in
            guard case CaptureQueryResolver.Error.noMatches = error else {
                return XCTFail("expected noMatches")
            }
        }
    }

    func testClearWinnerWhenTopScoreStrictlyGreater() throws {
        let windows = [
            window(id: 1, app: "Mail", title: "Chrome tips"),
            window(id: 2, app: "Google Chrome", title: "Inbox"),
        ]

        let result = try CaptureQueryResolver.resolve(query: "chrome", in: windows)

        guard case .matched(let window) = result else {
            return XCTFail("expected matched")
        }
        XCTAssertEqual(window.id, 2)
    }
}
