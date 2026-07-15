import CoreGraphics
import LilshotCore
import Vision

public struct VisionTextRecognizer: TextRecognizing {
    public init() {}

    public func recognize(in image: CGImage) async throws -> [(String, CGRect)] {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["vi-VN", "en-US"]

        let handler = VNImageRequestHandler(cgImage: image)
        try handler.perform([request])

        return request.results?.compactMap { observation in
            guard let text = observation.topCandidates(1).first?.string else { return nil }
            return (text, observation.boundingBox)
        } ?? []
    }
}
