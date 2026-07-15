import AppKit
import Carbon.HIToolbox
import LilshotCore

/// One failed `RegisterEventHotKey` attempt (label + OSStatus).
struct HotkeyRegistrationFailure: Equatable, Sendable {
    let label: String
    let status: OSStatus
}

/// Global hotkeys via Carbon `RegisterEventHotKey` — no third-party deps.
/// ⌥⇧S picker · ⌥⇧R re-capture · ⌥⇧F fullscreen · ⌥⇧A region.
final class HotkeyMonitor: @unchecked Sendable {
    var onHotkey: (() -> Void)?
    var onRecaptureLast: (() -> Void)?
    var onFullscreenCapture: (() -> Void)?
    var onRegionCapture: (() -> Void)?

    private var pickHotKeyRef: EventHotKeyRef?
    private var recaptureHotKeyRef: EventHotKeyRef?
    private var fullscreenHotKeyRef: EventHotKeyRef?
    private var regionHotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?

    private let signature = OSType(0x4C53484B) // "LSHK"
    private lazy var pickHotKeyID = EventHotKeyID(signature: signature, id: 1)
    private lazy var recaptureHotKeyID = EventHotKeyID(signature: signature, id: 2)
    private lazy var fullscreenHotKeyID = EventHotKeyID(signature: signature, id: 3)
    private lazy var regionHotKeyID = EventHotKeyID(signature: signature, id: 4)

    /// Installs the handler, then registers each hotkey independently.
    /// Returns failures for keys that did not register; does not abandon siblings.
    @discardableResult
    func register() throws -> [HotkeyRegistrationFailure] {
        unregister()

        var handlerRef: EventHandlerRef?
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, userData) -> OSStatus in
                guard let userData else { return OSStatus(eventNotHandledErr) }
                let monitor = Unmanaged<HotkeyMonitor>.fromOpaque(userData).takeUnretainedValue()

                var eventHotKeyID = EventHotKeyID()
                let err = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &eventHotKeyID
                )
                guard err == noErr else {
                    return OSStatus(eventNotHandledErr)
                }
                switch eventHotKeyID.id {
                case 1: monitor.onHotkey?()
                case 2: monitor.onRecaptureLast?()
                case 3: monitor.onFullscreenCapture?()
                case 4: monitor.onRegionCapture?()
                default: return OSStatus(eventNotHandledErr)
                }
                return noErr
            },
            1,
            [EventTypeSpec(
                eventClass: OSType(kEventClassKeyboard),
                eventKind: UInt32(kEventHotKeyPressed)
            )],
            Unmanaged.passUnretained(self).toOpaque(),
            &handlerRef
        )
        guard status == noErr else {
            throw HotkeyError.installHandler(status)
        }
        self.handlerRef = handlerRef

        let modifiers = UInt32(optionKey | shiftKey)
        var failures: [HotkeyRegistrationFailure] = []
        attemptKey(UInt32(kVK_ANSI_S), modifiers, pickHotKeyID, &pickHotKeyRef, "⌥⇧S", &failures)
        attemptKey(UInt32(kVK_ANSI_R), modifiers, recaptureHotKeyID, &recaptureHotKeyRef, "⌥⇧R", &failures)
        attemptKey(UInt32(kVK_ANSI_F), modifiers, fullscreenHotKeyID, &fullscreenHotKeyRef, "⌥⇧F", &failures)
        attemptKey(UInt32(kVK_ANSI_A), modifiers, regionHotKeyID, &regionHotKeyRef, "⌥⇧A", &failures)
        return failures
    }

    func unregister() {
        for ref in [pickHotKeyRef, recaptureHotKeyRef, fullscreenHotKeyRef, regionHotKeyRef] {
            if let ref { UnregisterEventHotKey(ref) }
        }
        pickHotKeyRef = nil
        recaptureHotKeyRef = nil
        fullscreenHotKeyRef = nil
        regionHotKeyRef = nil
        if let handlerRef {
            RemoveEventHandler(handlerRef)
            self.handlerRef = nil
        }
    }

    deinit {
        unregister()
    }

    private func attemptKey(
        _ keyCode: UInt32,
        _ modifiers: UInt32,
        _ id: EventHotKeyID,
        _ ref: inout EventHotKeyRef?,
        _ label: String,
        _ failures: inout [HotkeyRegistrationFailure]
    ) {
        var hotKeyRef: EventHotKeyRef?
        let registerStatus = RegisterEventHotKey(
            keyCode,
            modifiers,
            id,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        guard registerStatus == noErr else {
            fputs("hotkey \(label) failed: OSStatus \(registerStatus)\n", stderr)
            failures.append(HotkeyRegistrationFailure(label: label, status: registerStatus))
            return
        }
        ref = hotKeyRef
    }

    enum HotkeyError: LocalizedError {
        case installHandler(OSStatus)

        var errorDescription: String? {
            switch self {
            case .installHandler(let status):
                return "Failed to install hotkey handler (OSStatus \(status))"
            }
        }
    }

    /// Readable one-line summary for AppDelegate logging.
    static func failureSummary(_ failures: [HotkeyRegistrationFailure]) -> String {
        HotkeyFailureFormatting.summary(
            labelsAndStatuses: failures.map { ($0.label, $0.status) }
        )
    }
}
