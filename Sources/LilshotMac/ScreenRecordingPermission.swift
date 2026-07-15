import CoreGraphics
import Foundation

public enum ScreenRecordingPermission {
    /// Prefers an existing grant; requests access and fails clearly when denied.
    public static func ensureGranted() throws {
        if CGPreflightScreenCaptureAccess() {
            return
        }
        _ = CGRequestScreenCaptureAccess()
        if CGPreflightScreenCaptureAccess() {
            return
        }
        throw PermissionError.denied
    }

    public enum PermissionError: LocalizedError {
        case denied

        public var errorDescription: String? {
            """
            Screen Recording permission is required.
            Grant it in System Settings → Privacy & Security → Screen Recording, then re-run.
            """
        }
    }
}
