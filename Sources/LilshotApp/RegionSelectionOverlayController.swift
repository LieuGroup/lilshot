import AppKit

/// Transparent full-display overlay: crosshair drag selects a rect; Esc cancels.
@MainActor
final class RegionSelectionOverlayController {
    var onSelect: ((CGRect) -> Void)?
    var onCancel: (() -> Void)?

    private var window: NSWindow?
    private var keyMonitor: Any?
    private var cursorPushed = false

    var isActive: Bool { window?.isVisible == true }

    func begin() {
        tearDownMonitorsAndWindow()

        guard let screen = NSScreen.main else {
            onCancel?()
            return
        }

        let view = RegionSelectionView()
        view.onCommit = { [weak self] rect in
            self?.finish(selected: rect)
        }
        view.onCancel = { [weak self] in
            self?.finish(selected: nil)
        }

        let win = NSWindow(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false,
            screen: screen
        )
        win.isOpaque = false
        win.backgroundColor = .clear
        win.hasShadow = false
        win.level = .screenSaver
        win.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        win.ignoresMouseEvents = false
        win.acceptsMouseMovedEvents = true
        win.contentView = view
        win.isReleasedWhenClosed = false

        NSCursor.crosshair.push()
        cursorPushed = true

        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard event.keyCode == 53 else { return event } // Esc
            self?.finish(selected: nil)
            return nil
        }

        window = win
        NSApp.activate(ignoringOtherApps: true)
        win.makeKeyAndOrderFront(nil)
    }

    func end(notifyCancel: Bool = true) {
        tearDownMonitorsAndWindow()
        if notifyCancel {
            onCancel?()
        }
    }

    private func finish(selected: CGRect?) {
        tearDownMonitorsAndWindow()
        if let selected {
            onSelect?(selected)
        } else {
            onCancel?()
        }
    }

    private func tearDownMonitorsAndWindow() {
        if let keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
            self.keyMonitor = nil
        }
        if cursorPushed {
            NSCursor.pop()
            cursorPushed = false
        }
        window?.orderOut(nil)
        window = nil
    }
}
