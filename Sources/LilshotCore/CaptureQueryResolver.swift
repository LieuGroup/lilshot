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

        return .ambiguous(ranked)
    }

    private static func isAllDigits(_ string: String) -> Bool {
        !string.isEmpty && string.unicodeScalars.allSatisfy { CharacterSet.decimalDigits.contains($0) }
    }
}
