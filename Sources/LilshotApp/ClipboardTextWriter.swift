import AppKit

enum ClipboardTextWriter {
    enum WriteError: LocalizedError {
        case writeFailed

        var errorDescription: String? { "Failed to write text to clipboard" }
    }

    static func write(_ text: String) throws {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        guard pasteboard.setString(text, forType: .string) else {
            throw WriteError.writeFailed
        }
    }
}
