import AppKit

@MainActor
final class StatusBarController: NSObject {
    private let statusItem: NSStatusItem
    private let onPickWindow: () -> Void
    private let onQuit: () -> Void

    init(onPickWindow: @escaping () -> Void, onQuit: @escaping () -> Void) {
        self.onPickWindow = onPickWindow
        self.onQuit = onQuit
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()

        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "camera.viewfinder",
                accessibilityDescription: "lilshot"
            )
        }

        let menu = NSMenu()
        let pick = NSMenuItem(
            title: "Pick window",
            action: #selector(pickWindow),
            keyEquivalent: ""
        )
        pick.target = self
        menu.addItem(pick)
        menu.addItem(.separator())
        let quit = NSMenuItem(
            title: "Quit",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quit.target = self
        menu.addItem(quit)
        statusItem.menu = menu
    }

    @objc private func pickWindow() {
        onPickWindow()
    }

    @objc private func quitApp() {
        onQuit()
    }
}
