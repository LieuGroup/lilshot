import ArgumentParser
import Foundation
import LilshotCore
import LilshotMac

enum WindowQueryResolver {
    static func resolve(_ query: String) async throws -> WindowInfo {
        let provider = ScreenCaptureWindowProvider()
        let windows = WindowNoiseFilter.apply(to: try await provider.windows())

        let resolved: CaptureQueryResolver.Result
        do {
            resolved = try CaptureQueryResolver.resolve(query: query, in: windows)
        } catch CaptureQueryResolver.Error.windowNotFound(let id) {
            fputs("No window found with ID \(id)\n", stderr)
            throw ExitCode(1)
        } catch CaptureQueryResolver.Error.noMatches {
            fputs("No windows matched query \"\(query)\"\n", stderr)
            throw ExitCode(1)
        }

        switch resolved {
        case .matched(let window):
            return window
        case .ambiguous(let candidates):
            fputs("Ambiguous query \"\(query)\". Candidates:\n", stderr)
            for scored in candidates {
                let window = scored.window
                let title = window.title.isEmpty ? "-" : window.title
                fputs(
                    "  \(window.id)\t\(window.appName)\t\(title)\t\(window.width)x\(window.height)\tscore=\(scored.score)\n",
                    stderr
                )
            }
            throw ExitCode(2)
        }
    }
}
