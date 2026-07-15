import Foundation

public struct ScoredWindow: Equatable, Sendable {
    public let window: WindowInfo
    public let score: Int

    public init(window: WindowInfo, score: Int) {
        self.window = window
        self.score = score
    }
}

public enum FuzzyMatcher {
    /// App-name hits always outrank title-only hits of equal quality.
    private static let appNameBonus = 1_000

    public static func rank(query: String, in windows: [WindowInfo]) -> [ScoredWindow] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return windows.map { ScoredWindow(window: $0, score: 0) }
        }

        let normalizedQuery = normalize(trimmed)
        var scored: [ScoredWindow] = []

        for window in windows {
            let appScore = scoreMatch(query: normalizedQuery, in: normalize(window.appName))
            let titleScore = scoreMatch(query: normalizedQuery, in: normalize(window.title))

            let best: (score: Int, targetLength: Int)?
            if let app = appScore, let title = titleScore {
                let withAppBonus = app.score + appNameBonus
                if withAppBonus >= title.score {
                    best = (withAppBonus, app.targetLength)
                } else {
                    best = title
                }
            } else if let app = appScore {
                best = (app.score + appNameBonus, app.targetLength)
            } else if let title = titleScore {
                best = title
            } else {
                best = nil
            }

            if let best {
                scored.append(ScoredWindow(window: window, score: best.score))
            }
        }

        return scored.sorted { lhs, rhs in
            if lhs.score != rhs.score { return lhs.score > rhs.score }

            let lhsTarget = tieBreakLength(query: normalizedQuery, window: lhs.window)
            let rhsTarget = tieBreakLength(query: normalizedQuery, window: rhs.window)
            if lhsTarget != rhsTarget { return lhsTarget < rhsTarget }

            return lhs.window.id < rhs.window.id
        }
    }

    private static func tieBreakLength(query: String, window: WindowInfo) -> Int {
        let app = normalize(window.appName)
        let title = normalize(window.title)
        let appMatch = scoreMatch(query: query, in: app) != nil
        let titleMatch = scoreMatch(query: query, in: title) != nil

        if appMatch && titleMatch {
            return min(app.count, title.count)
        }
        if appMatch { return app.count }
        if titleMatch { return title.count }
        return Int.max
    }

    private static func scoreMatch(query: String, in target: String) -> (score: Int, targetLength: Int)? {
        guard !query.isEmpty, !target.isEmpty else { return nil }
        guard let match = subsequenceMatch(query: query, in: target) else { return nil }

        var score = 10
        if match.isPrefix { score += 40 }
        score += match.wordBoundaryHits * 15
        score += match.maxConsecutiveRun * 5
        score += max(0, 20 - match.span)

        return (score, target.count)
    }

    private struct MatchDetails {
        let isPrefix: Bool
        let wordBoundaryHits: Int
        let maxConsecutiveRun: Int
        let span: Int
    }

    /// Greedy left-to-right subsequence match; returns nil when query is not a subsequence.
    private static func subsequenceMatch(query: String, in target: String) -> MatchDetails? {
        let queryChars = Array(query)
        let targetChars = Array(target)
        var positions: [Int] = []
        var ti = 0

        for qc in queryChars {
            while ti < targetChars.count, targetChars[ti] != qc {
                ti += 1
            }
            guard ti < targetChars.count else { return nil }
            positions.append(ti)
            ti += 1
        }

        let isPrefix = positions[0] == 0
        var wordBoundaryHits = 0
        for pos in positions {
            if pos == 0 || targetChars[pos - 1] == " " {
                wordBoundaryHits += 1
            }
        }

        var maxRun = 1
        var currentRun = 1
        for i in 1..<positions.count {
            if positions[i] == positions[i - 1] + 1 {
                currentRun += 1
                maxRun = max(maxRun, currentRun)
            } else {
                currentRun = 1
            }
        }

        let span = positions.last! - positions.first! + 1
        return MatchDetails(
            isPrefix: isPrefix,
            wordBoundaryHits: wordBoundaryHits,
            maxConsecutiveRun: maxRun,
            span: span
        )
    }

    private static func normalize(_ string: String) -> String {
        // đ/Đ are stroke letters, not combining diacritics — folding leaves them intact.
        string
            .replacingOccurrences(of: "đ", with: "d")
            .replacingOccurrences(of: "Đ", with: "D")
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .lowercased()
    }
}
