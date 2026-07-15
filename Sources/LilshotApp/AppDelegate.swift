import AppKit
import LilshotMac

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBar: StatusBarController?
    private var hotkey: HotkeyMonitor?
    private var picker: PickerPanelController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppMainMenu.install()

        let provider = ScreenCaptureWindowProvider()
        let capturer = ScreenCaptureWindowCapturer()

        let pickerController = PickerPanelController(
            provider: provider,
            capturer: capturer
        )
        self.picker = pickerController

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
            Task { @MainActor in
                pickerController?.toggle()
            }
        }
        monitor.onRecaptureLast = { [weak pickerController] in
            Task { @MainActor in
                pickerController?.recaptureLast()
            }
        }
        do {
            try monitor.register()
        } catch {
            fputs("hotkey registration failed: \(error.localizedDescription)\n", stderr)
        }
        self.hotkey = monitor
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotkey?.unregister()
    }
}
