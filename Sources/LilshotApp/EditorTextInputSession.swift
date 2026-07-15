import AppKit
import LilshotCore

/// Inline NSTextField placed on the canvas; Enter commits, Esc cancels.
final class EditorTextInputSession: NSObject, NSTextFieldDelegate {
    var onCommit: ((CGPoint, String) -> Void)?
    var onCancel: (() -> Void)?

    private weak var host: NSView?
    private var field: NSTextField?
    private var imageOrigin: CGPoint?
    private var monitor: Any?

    var isActive: Bool { field != nil }

    func begin(
        at viewPoint: CGPoint,
        imageOrigin: CGPoint,
        fontSize: CGFloat,
        color: NSColor,
        in host: NSView
    ) {
        cancel()
        self.host = host
        self.imageOrigin = imageOrigin

        let field = NSTextField(frame: NSRect(
            x: viewPoint.x,
            y: viewPoint.y - fontSize,
            width: max(120, fontSize * 8),
            height: fontSize * 1.4
        ))
        field.font = NSFont.systemFont(ofSize: fontSize)
        field.textColor = color
        field.backgroundColor = NSColor.textBackgroundColor.withAlphaComponent(0.9)
        field.isBordered = true
        field.isBezeled = true
        field.bezelStyle = .squareBezel
        field.focusRingType = .none
        field.delegate = self
        host.addSubview(field)
        host.window?.makeFirstResponder(field)
        self.field = field

        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, event.window === host.window else { return event }
            if event.keyCode == 36 { // Return
                self.commit()
                return nil
            }
            if event.keyCode == 53 { // Esc
                self.cancel()
                return nil
            }
            return event
        }
    }

    func commit() {
        guard let origin = imageOrigin, let field else {
            cancel()
            return
        }
        let text = field.stringValue
        tearDown()
        onCommit?(origin, text)
    }

    func cancel() {
        let wasActive = isActive
        tearDown()
        if wasActive { onCancel?() }
    }

    func controlTextDidEndEditing(_ obj: Notification) {
        // Click-away: commit non-empty, otherwise cancel.
        guard let field else { return }
        if field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            cancel()
        } else {
            commit()
        }
    }

    private func tearDown() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
        let active = field
        field = nil
        imageOrigin = nil
        active?.delegate = nil
        active?.removeFromSuperview()
        if let host {
            host.window?.makeFirstResponder(host)
        }
    }
}
