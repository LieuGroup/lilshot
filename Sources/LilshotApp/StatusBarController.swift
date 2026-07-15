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
            button.image = Self.menubarImage()
            button.imagePosition = .imageOnly
            button.toolTip = "lilshot"
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

    /// Template silhouette from bundled assets (adapts to light/dark menu bar).
    private static func menubarImage() -> NSImage {
        let image = NSImage(size: NSSize(width: 18, height: 18))
        if let url = Bundle.module.url(
            forResource: "menubar-icon",
            withExtension: "png",
            subdirectory: "assets"
        ),
           let rep = NSImageRep(contentsOf: url) {
            image.addRepresentation(rep)
        }
        if let url2x = Bundle.module.url(
            forResource: "menubar-icon@2x",
            withExtension: "png",
            subdirectory: "assets"
        ),
           let data2x = try? Data(contentsOf: url2x),
           let rep2x = NSBitmapImageRep(data: data2x) {
            rep2x.size = NSSize(
                width: CGFloat(rep2x.pixelsWide) / 2,
                height: CGFloat(rep2x.pixelsHigh) / 2
            )
            image.addRepresentation(rep2x)
        }
        image.isTemplate = true
        return image
    }
}
