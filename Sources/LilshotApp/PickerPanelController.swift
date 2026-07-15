import AppKit
import LilshotCore
import LilshotMac
import SwiftUI

@MainActor
final class PickerPanelController {
    private let session: PickerSession
    private let capturer: any WindowCapturing
    private var panel: NSPanel?
    private var isCapturing = false

    init(provider: any WindowProviding, capturer: any WindowCapturing) {
        self.capturer = capturer
        self.session = PickerSession(provider: provider, capturer: capturer)
    }

    func toggle() {
        if panel?.isVisible == true {
            close()
        } else {
            show()
        }
    }

    func show() {
        do {
            try ScreenRecordingPermission.ensureGranted()
        } catch {
            fputs("\(error.localizedDescription)\n", stderr)
            return
        }

        let panel = panel ?? makePanel()
        self.panel = panel

        Task {
            await session.reload()
            panel.center()
            NSApp.activate(ignoringOtherApps: true)
            panel.makeKeyAndOrderFront(nil)
        }
    }

    func close() {
        panel?.orderOut(nil)
        session.resetForClose()
    }

    private func makePanel() -> NSPanel {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 720, height: 420),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.title = "lilshot"
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]

        let root = PickerContentView(
            session: session,
            previewStore: session.previewStore,
            onCapture: { [weak self] in
                self?.captureSelected()
            },
            onCancel: { [weak self] in
                self?.close()
            }
        )
        let hosting = NSHostingView(rootView: root)
        hosting.frame = panel.contentView?.bounds ?? .zero
        hosting.autoresizingMask = [.width, .height]
        panel.contentView = hosting
        return panel
    }

    private func captureSelected() {
        guard !isCapturing, let window = session.selectedWindow else { return }
        isCapturing = true
        Task {
            defer { isCapturing = false }
            do {
                let image = try await capturer.captureImage(windowID: window.id, scale: 2)
                try ClipboardImageWriter.write(image)
                close()
            } catch {
                fputs("capture failed: \(error.localizedDescription)\n", stderr)
            }
        }
    }
}
