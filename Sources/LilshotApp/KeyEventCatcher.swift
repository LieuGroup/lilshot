import AppKit
import SwiftUI

/// Captures arrow / Enter / Esc when the search field or list has focus.
struct KeyEventCatcher: NSViewRepresentable {
    var onUp: () -> Void
    var onDown: () -> Void
    var onEnter: () -> Void
    var onEscape: () -> Void

    func makeNSView(context: Context) -> KeyCatcherView {
        let view = KeyCatcherView()
        view.onUp = onUp
        view.onDown = onDown
        view.onEnter = onEnter
        view.onEscape = onEscape
        return view
    }

    func updateNSView(_ nsView: KeyCatcherView, context: Context) {
        nsView.onUp = onUp
        nsView.onDown = onDown
        nsView.onEnter = onEnter
        nsView.onEscape = onEscape
    }
}

final class KeyCatcherView: NSView {
    var onUp: (() -> Void)?
    var onDown: (() -> Void)?
    var onEnter: (() -> Void)?
    var onEscape: (() -> Void)?
    private var monitor: Any?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil {
            installMonitor()
        } else {
            removeMonitor()
        }
    }

    deinit {
        removeMonitor()
    }

    private func installMonitor() {
        removeMonitor()
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            guard self.window?.isVisible == true else { return event }
            switch event.keyCode {
            case 126: // up
                self.onUp?()
                return nil
            case 125: // down
                self.onDown?()
                return nil
            case 36, 76: // return / keypad enter
                self.onEnter?()
                return nil
            case 53: // escape
                self.onEscape?()
                return nil
            default:
                return event
            }
        }
    }

    private func removeMonitor() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }
}
