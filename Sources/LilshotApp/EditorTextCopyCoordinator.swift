import CoreGraphics
import LilshotCore
import LilshotMac

@MainActor
final class EditorTextCopyCoordinator {
    private let recognizer: any TextRecognizing
    private var isRunning = false

    init(recognizer: any TextRecognizing = VisionTextRecognizer()) {
        self.recognizer = recognizer
    }

    func copyText(from image: CGImage?) {
        guard let image, !isRunning else { return }
        isRunning = true

        Task {
            defer { isRunning = false }
            do {
                let observations = try await recognizer.recognize(in: image)
                try ClipboardTextWriter.write(OCRTextAssembler.assemble(observations))
                CaptureFeedback.playSuccess()
            } catch {
                fputs("editor OCR failed: \(error.localizedDescription)\n", stderr)
                CaptureFeedback.playError()
            }
        }
    }
}
