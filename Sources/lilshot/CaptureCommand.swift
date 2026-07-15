import ArgumentParser
import Foundation
import LilshotCore
import LilshotMac

struct CaptureCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "capture",
        abstract: "Capture a window by ID or fuzzy query."
    )

    @Argument(help: "Window ID (digits) or fuzzy query against app name / title.")
    var query: String

    @Option(name: .shortAndLong, help: "Output PNG path. Defaults to ~/Desktop/lilshot-<app>-<timestamp>.png.")
    var output: String?

    func run() async throws {
        try ScreenRecordingPermission.ensureGranted()

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

        case .matched(let window):
            let path = output ?? CaptureOutputPath.default(for: window)
            let capturer = ScreenCaptureWindowCapturer()
            do {
                let image = try await capturer.captureImage(windowID: window.id, relativeScale: 1.0)
                try PNGWriter.write(image, to: path)
                print(path)
            } catch {
                fputs("capture failed: \(error.localizedDescription)\n", stderr)
                throw ExitCode(1)
            }
        }
    }
}
