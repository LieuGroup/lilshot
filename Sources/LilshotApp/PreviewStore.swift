import AppKit
import CoreGraphics
import LilshotCore

/// Loads and caches live window previews at preview scale for the panel lifetime.
@MainActor
final class PreviewStore: ObservableObject {
    @Published private(set) var images: [UInt32: NSImage] = [:]
    @Published private(set) var inFlight: Set<UInt32> = []

    private let capturer: any WindowCapturing
    private let previewScale: Double
    private var tasks: [UInt32: Task<Void, Never>] = [:]

    init(capturer: any WindowCapturing, previewScale: Double = 0.5) {
        self.capturer = capturer
        self.previewScale = previewScale
    }

    func image(for windowID: UInt32) -> NSImage? {
        images[windowID]
    }

    func isLoading(_ windowID: UInt32) -> Bool {
        inFlight.contains(windowID)
    }

    func clear() {
        for task in tasks.values {
            task.cancel()
        }
        tasks.removeAll()
        images.removeAll()
        inFlight.removeAll()
    }

    /// Kick off captures in `priority` order; skips IDs already cached or loading.
    func enqueue(windowIDs: [UInt32]) {
        for windowID in windowIDs {
            guard images[windowID] == nil, tasks[windowID] == nil else { continue }
            inFlight.insert(windowID)
            let capturer = self.capturer
            let scale = previewScale
            tasks[windowID] = Task { [weak self] in
                defer {
                    Task { @MainActor in
                        self?.tasks[windowID] = nil
                        self?.inFlight.remove(windowID)
                    }
                }
                do {
                    let cgImage = try await capturer.captureImage(windowID: windowID, scale: scale)
                    let nsImage = NSImage(
                        cgImage: cgImage,
                        size: NSSize(width: cgImage.width, height: cgImage.height)
                    )
                    await MainActor.run {
                        self?.images[windowID] = nsImage
                    }
                } catch {
                    if !Task.isCancelled {
                        fputs(
                            "preview failed for window \(windowID): \(error.localizedDescription)\n",
                            stderr
                        )
                    }
                }
            }
        }
    }
}
