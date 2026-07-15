import ArgumentParser
import Foundation
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

        let window = try await WindowQueryResolver.resolve(query)
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
