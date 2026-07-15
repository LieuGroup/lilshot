import AppKit
import CoreGraphics
import LilshotCore

/// Loads and caches live window previews at preview scale for the panel lifetime.
/// At most `maxConcurrent` captures run at once; newest selection priority wins.
@MainActor
final class PreviewStore: ObservableObject {
    @Published private(set) var images: [UInt32: NSImage] = [:]
    @Published private(set) var inFlight: Set<UInt32> = []

    private let capturer: any WindowCapturing
    private let previewScale: Double
    private var queue: PreviewAdmissionQueue
    private var generation: UInt64 = 0

    init(
        capturer: any WindowCapturing,
        previewScale: Double = 0.5,
        maxConcurrent: Int = 2
    ) {
        self.capturer = capturer
        self.previewScale = previewScale
        self.queue = PreviewAdmissionQueue(maxConcurrent: maxConcurrent)
    }

    func image(for windowID: UInt32) -> NSImage? {
        images[windowID]
    }

    func isLoading(_ windowID: UInt32) -> Bool {
        inFlight.contains(windowID)
    }

    func clear() {
        generation &+= 1
        queue.reset()
        images.removeAll()
        inFlight.removeAll()
    }

    /// Enqueue captures in priority order (front = highest). At most two run concurrently.
    func enqueue(windowIDs: [UInt32]) {
        for windowID in windowIDs where images[windowID] != nil {
            queue.markCached(windowID)
        }
        let needed = windowIDs.filter { images[$0] == nil }
        guard !needed.isEmpty else { return }
        queue.enqueue(ids: needed)
        pump()
    }

    private func pump() {
        while let windowID = queue.next() {
            queue.markStarted(windowID)
            inFlight.insert(windowID)
            let capturer = self.capturer
            let scale = previewScale
            let gen = generation
            Task { [weak self] in
                let captured: NSImage?
                do {
                    let cgImage = try await capturer.captureImage(windowID: windowID, scale: scale)
                    captured = NSImage(
                        cgImage: cgImage,
                        size: NSSize(width: cgImage.width, height: cgImage.height)
                    )
                } catch {
                    fputs(
                        "preview failed for window \(windowID): \(error.localizedDescription)\n",
                        stderr
                    )
                    captured = nil
                }
                await MainActor.run {
                    guard let self, self.generation == gen else { return }
                    if let captured {
                        self.images[windowID] = captured
                        self.queue.markCached(windowID)
                    }
                    self.queue.markFinished(windowID)
                    self.inFlight.remove(windowID)
                    self.pump()
                }
            }
        }
    }
}
