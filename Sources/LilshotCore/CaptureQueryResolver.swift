import Foundation

public enum CaptureQueryResolver {
    public enum Result: Equatable, Sendable {
        case matched(WindowInfo)
        case ambiguous([ScoredWindow])
    }

    public enum Error: Swift.Error, Equatable {
        case windowNotFound(UInt32)
        case noMatches
    }

    public static func resolve(query: String, in windows: [WindowInfo]) throws -> Result {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

        if isAllDigits(trimmed), let windowID = UInt32(trimmed) {
            guard let window = windows.first(where: { $0.id == windowID }) else {
                throw Error.windowNotFound(windowID)
            }
            return .matched(window)
        }

        let ranked = FuzzyMatcher.rank(query: trimmed, in: windows)
        guard let top = ranked.first else {
            throw Error.noMatches
        }

        if ranked.count == 1 {
            return .matched(top.window)
        }

        let runnerUp = ranked[1]
        if top.score > runnerUp.score {
            return .matched(top.window)
        }

        let tied = ranked.filter { $0.score == top.score }
        let appNames = Set(tied.map(\.window.appName))
        if appNames.count == 1 {
            let winner = tied.dropFirst().reduce(tied[0].window) { preferredWindow($0, $1.window) }
            return .matched(winner)
        }

        return .ambiguous(ranked)
    }

    /// Same-app score ties: prefer non-empty title, then larger area, then lower id.
    private static func preferredWindow(_ lhs: WindowInfo, _ rhs: WindowInfo) -> WindowInfo {
        let lhsHasTitle = !lhs.title.isEmpty
        let rhsHasTitle = !rhs.title.isEmpty
        if lhsHasTitle != rhsHasTitle { return lhsHasTitle ? lhs : rhs }

        let lhsArea = lhs.width * lhs.height
        let rhsArea = rhs.width * rhs.height
        if lhsArea != rhsArea { return lhsArea > rhsArea ? lhs : rhs }

        return lhs.id < rhs.id ? lhs : rhs
    }

    private static func isAllDigits(_ string: String) -> Bool {
        !string.isEmpty && string.unicodeScalars.allSatisfy { CharacterSet.decimalDigits.contains($0) }
    }
}
