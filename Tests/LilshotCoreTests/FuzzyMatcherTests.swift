import XCTest
@testable import LilshotCore

final class FuzzyMatcherTests: XCTestCase {
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

    func testRanksChromeByAppNameSubsequence() {
        let windows = [
            window(id: 1, app: "Safari"),
            window(id: 2, app: "Google Chrome"),
            window(id: 3, app: "Notes"),
        ]

        let ranked = FuzzyMatcher.rank(query: "chr", in: windows)

        XCTAssertEqual(ranked.map(\.window.id), [2])
        XCTAssertGreaterThan(ranked[0].score, 0)
    }

    func testMatchesChromeWindowByTitle() {
        let windows = [
            window(id: 10, app: "Google Chrome", title: "Grok — xAI"),
            window(id: 11, app: "Notes", title: "Shopping"),
            window(id: 12, app: "Terminal", title: "zsh"),
        ]

        let ranked = FuzzyMatcher.rank(query: "grok", in: windows)

        XCTAssertEqual(ranked.map(\.window.id), [10])
    }

    func testVietnameseDiacriticsMatchASCIITitles() {
        let windows = [
            window(id: 1, app: "Notes", title: "Hop dong"),
            window(id: 2, app: "Preview", title: "Invoice"),
        ]

        let ranked = FuzzyMatcher.rank(query: "hợp đồng", in: windows)

        XCTAssertEqual(ranked.map(\.window.id), [1])
    }

    func testASCIIQueryMatchesVietnameseTitles() {
        let windows = [
            window(id: 1, app: "Notes", title: "Hợp đồng"),
            window(id: 2, app: "Preview", title: "Invoice"),
        ]

        let ranked = FuzzyMatcher.rank(query: "hop dong", in: windows)

        XCTAssertEqual(ranked.map(\.window.id), [1])
    }

    func testAppNameMatchOutranksTitleMatch() {
        let windows = [
            window(id: 1, app: "Mail", title: "Chrome tips"),
            window(id: 2, app: "Google Chrome", title: "Inbox"),
        ]

        let ranked = FuzzyMatcher.rank(query: "chrome", in: windows)

        XCTAssertEqual(ranked.first?.window.id, 2)
        XCTAssertGreaterThan(ranked[0].score, ranked[1].score)
    }

    func testChromeRanksShorterAppNameAboveAutoFillGoogleChrome() {
        let windows = [
            window(id: 1, app: "AutoFill (Google Chrome)"),
            window(id: 2, app: "Google Chrome"),
        ]

        let ranked = FuzzyMatcher.rank(query: "chrome", in: windows)

        XCTAssertEqual(ranked.map(\.window.id), [2, 1])
        XCTAssertGreaterThan(ranked[0].score, ranked[1].score)
    }

    func testTieBreakPrefersShorterTargetThenLowerID() {
        let windows = [
            window(id: 20, app: "Code"),
            window(id: 10, app: "Code"),
            window(id: 5, app: "Code Editor"),
        ]

        let ranked = FuzzyMatcher.rank(query: "code", in: windows)

        XCTAssertEqual(ranked.map(\.window.id), [10, 20, 5])
    }

    func testEmptyQueryReturnsAllWindowsInInputOrderWithZeroScore() {
        let windows = [
            window(id: 3, app: "Notes"),
            window(id: 1, app: "Safari"),
            window(id: 2, app: "Terminal"),
        ]

        let ranked = FuzzyMatcher.rank(query: "   ", in: windows)

        XCTAssertEqual(ranked.map(\.window.id), [3, 1, 2])
        XCTAssertTrue(ranked.allSatisfy { $0.score == 0 })
    }

    func testNoMatchReturnsEmpty() {
        let windows = [
            window(id: 1, app: "Safari", title: "Apple"),
            window(id: 2, app: "Notes", title: "Todos"),
        ]

        let ranked = FuzzyMatcher.rank(query: "zzzz", in: windows)

        XCTAssertTrue(ranked.isEmpty)
    }

    func testCaseInsensitiveMatching() {
        let windows = [window(id: 1, app: "Finder")]

        let ranked = FuzzyMatcher.rank(query: "FIND", in: windows)

        XCTAssertEqual(ranked.map(\.window.id), [1])
    }
}
