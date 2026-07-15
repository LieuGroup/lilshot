import ArgumentParser
import Foundation
import LilshotCore
import LilshotMac

struct OCRCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "ocr",
        abstract: "Recognize text in a window by ID or fuzzy query."
    )

    @Argument(help: "Window ID (digits) or fuzzy query against app name / title.")
    var query: String

    func run() async throws {
        try ScreenRecordingPermission.ensureGranted()
        let window = try await WindowQueryResolver.resolve(query)

        do {
            let image = try await ScreenCaptureWindowCapturer().captureImage(
                windowID: window.id,
                relativeScale: 1.0
            )
            let observations = try await VisionTextRecognizer().recognize(in: image)
            print(OCRTextAssembler.assemble(observations))
        } catch {
            fputs("OCR failed: \(error.localizedDescription)\n", stderr)
            throw ExitCode(1)
        }
    }
}
