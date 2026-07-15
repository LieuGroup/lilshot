import AppKit

enum AppMainMenu {
    /// Main menu so `.accessory` apps still get Edit/File key equivalents.
    static func install() {
        let mainMenu = NSMenu()

        let appItem = NSMenuItem()
        mainMenu.addItem(appItem)
        let appMenu = NSMenu()
        appItem.submenu = appMenu
        appMenu.addItem(
            withTitle: "Quit lilshot",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )

        let fileItem = NSMenuItem()
        mainMenu.addItem(fileItem)
        let file = NSMenu(title: "File")
        fileItem.submenu = file
        file.addItem(
            withTitle: "Save",
            action: #selector(EditorWindowController.saveDocument(_:)),
            keyEquivalent: "s"
        )
        file.addItem(withTitle: "Close", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")

        let editItem = NSMenuItem()
        mainMenu.addItem(editItem)
        let edit = NSMenu(title: "Edit")
        editItem.submenu = edit
        edit.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        let redo = edit.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "z")
        redo.keyEquivalentModifierMask = [.command, .shift]
        edit.addItem(.separator())
        edit.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        edit.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        edit.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        edit.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")

        let viewItem = NSMenuItem()
        mainMenu.addItem(viewItem)
        let view = NSMenu(title: "View")
        viewItem.submenu = view
        view.addItem(
            withTitle: "Zoom to Fit",
            action: #selector(EditorWindowController.zoomToFit(_:)),
            keyEquivalent: "0"
        )
        view.addItem(
            withTitle: "Actual Size",
            action: #selector(EditorWindowController.zoomActualSize(_:)),
            keyEquivalent: "9"
        )

        NSApp.mainMenu = mainMenu
    }
}
