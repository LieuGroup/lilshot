import AppKit
import LilshotCore
import LilshotMac

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBar: StatusBarController?
    private var hotkey: HotkeyMonitor?
    private var picker: PickerPanelController?
    private var regionOverlay: RegionSelectionOverlayController?
    private let displayCapturer: any DisplayCapturing = ScreenCaptureDisplayCapturer()
    private var isDisplayCapturing = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppMainMenu.install()

        let provider = ScreenCaptureWindowProvider()
        let capturer = ScreenCaptureWindowCapturer()

        let pickerController = PickerPanelController(
            provider: provider,
            capturer: capturer
        )
        self.picker = pickerController

        let overlay = RegionSelectionOverlayController()
        overlay.onSelect = { [weak self] rect in
            self?.captureSelectedRegion(rect)
        }
        self.regionOverlay = overlay

        let status = StatusBarController(
            onPickWindow: { [weak pickerController] in
                pickerController?.toggle()
            },
            onQuit: {
                NSApp.terminate(nil)
            }
        )
        self.statusBar = status

        let monitor = HotkeyMonitor()
        monitor.onHotkey = { [weak pickerController] in
            Task { @MainActor in pickerController?.toggle() }
        }
        monitor.onRecaptureLast = { [weak pickerController] in
            Task { @MainActor in pickerController?.recaptureLast() }
        }
        monitor.onFullscreenCapture = { [weak self] in
            Task { @MainActor in self?.captureFullscreen() }
        }
        monitor.onRegionCapture = { [weak self] in
            Task { @MainActor in self?.beginRegionCapture() }
        }
        do {
            let failures = try monitor.register()
            if !failures.isEmpty {
                fputs(HotkeyMonitor.failureSummary(failures) + "\n", stderr)
            }
        } catch {
            fputs("hotkey registration failed: \(error.localizedDescription)\n", stderr)
        }
        self.hotkey = monitor
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotkey?.unregister()
        regionOverlay?.end(notifyCancel: false)
    }

    private func captureFullscreen() {
        guard !isDisplayCapturing, regionOverlay?.isActive != true else { return }
        do {
            try ScreenRecordingPermission.ensureGranted()
        } catch {
            fputs("\(error.localizedDescription)\n", stderr)
            CaptureFeedback.playError()
            return
        }
        isDisplayCapturing = true
        Task {
            defer { isDisplayCapturing = false }
            do {
                let image = try await displayCapturer.captureMainDisplay(relativeScale: 1.0)
                try ClipboardImageWriter.write(image)
                CaptureFeedback.playSuccess()
                if let frame = NSScreen.main?.frame {
                    CaptureFeedback.flash(over: frame)
                }
            } catch {
                fputs("fullscreen capture failed: \(error.localizedDescription)\n", stderr)
                CaptureFeedback.playError()
            }
        }
    }

    private func beginRegionCapture() {
        guard !isDisplayCapturing, regionOverlay?.isActive != true else { return }
        do {
            try ScreenRecordingPermission.ensureGranted()
        } catch {
            fputs("\(error.localizedDescription)\n", stderr)
            CaptureFeedback.playError()
            return
        }
        picker?.close()
        regionOverlay?.begin()
    }

    private func captureSelectedRegion(_ appKitRect: CGRect) {
        guard !isDisplayCapturing else { return }
        let displayHeight = NSScreen.main?.frame.height ?? appKitRect.maxY
        let sckRect = RegionGeometry.appKitRectToScreenCaptureKit(
            appKitRect,
            displayHeight: displayHeight
        )
        isDisplayCapturing = true
        Task {
            defer { isDisplayCapturing = false }
            do {
                let image = try await displayCapturer.captureMainDisplayRegion(sckRect, relativeScale: 1.0)
                try ClipboardImageWriter.write(image)
                CaptureFeedback.playSuccess()
                CaptureFeedback.flash(over: appKitRect)
            } catch {
                fputs("region capture failed: \(error.localizedDescription)\n", stderr)
                CaptureFeedback.playError()
            }
        }
    }
}
