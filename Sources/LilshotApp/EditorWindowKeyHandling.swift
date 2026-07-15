import AppKit
import LilshotCore

/// Editor window key routing: tools, delete, crop Enter, Esc, zoom.
enum EditorWindowKeyHandling {
    struct Actions {
        var selectTool: (EditorTool) -> Void
        var applyCrop: () -> Void
        var copyText: () -> Void
        var deleteSelected: () -> Void
        var close: () -> Void
        var setActualSize: (Bool) -> Void
        var isEditingText: () -> Bool
        var currentTool: () -> EditorTool
    }

    /// Returns nil when the event was handled (should be swallowed).
    static func handle(_ event: NSEvent, actions: Actions) -> NSEvent? {
        if actions.isEditingText() { return event }

        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        if flags == [.command, .shift], event.charactersIgnoringModifiers?.lowercased() == "t" {
            actions.copyText()
            return nil
        }
        if flags.contains(.command) {
            if event.charactersIgnoringModifiers == "0" {
                actions.setActualSize(false)
                return nil
            }
            if event.charactersIgnoringModifiers == "9" {
                actions.setActualSize(true)
                return nil
            }
            return event
        }

        // Ignore modified tool shortcuts (Shift/Option/Ctrl).
        guard flags.isEmpty else { return event }

        if event.keyCode == 36, actions.currentTool() == .crop {
            actions.applyCrop()
            return nil
        }
        if event.keyCode == 53 {
            actions.close()
            return nil
        }
        // Delete / Forward Delete
        if event.keyCode == 51 || event.keyCode == 117 {
            actions.deleteSelected()
            return nil
        }

        if let tool = tool(for: event.charactersIgnoringModifiers) {
            actions.selectTool(tool)
            return nil
        }
        return event
    }

    private static func tool(for characters: String?) -> EditorTool? {
        switch characters {
        case "v", "V": return .select
        case "a", "A": return .arrow
        case "r", "R": return .rect
        case "t", "T": return .text
        case "b", "B": return .blur
        case "n", "N": return .stepNumber
        case "c", "C": return .crop
        default: return nil
        }
    }
}
