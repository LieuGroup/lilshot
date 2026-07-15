import AppKit
import Carbon.HIToolbox

/// Global hotkeys via Carbon `RegisterEventHotKey` — no third-party deps.
/// ⌥⇧S opens the picker; ⌥⇧R re-captures the last window.
final class HotkeyMonitor: @unchecked Sendable {
    var onHotkey: (() -> Void)?
    var onRecaptureLast: (() -> Void)?

    private var pickHotKeyRef: EventHotKeyRef?
    private var recaptureHotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?
    private let pickHotKeyID = EventHotKeyID(
        signature: OSType(0x4C53484B), // "LSHK"
        id: 1
    )
    private let recaptureHotKeyID = EventHotKeyID(
        signature: OSType(0x4C53484B), // "LSHK"
        id: 2
    )

    func register() throws {
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
                case monitor.pickHotKeyID.id:
                    monitor.onHotkey?()
                    return noErr
                case monitor.recaptureHotKeyID.id:
                    monitor.onRecaptureLast?()
                    return noErr
                default:
                    return OSStatus(eventNotHandledErr)
                }
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
        try registerKey(
            keyCode: UInt32(kVK_ANSI_S),
            modifiers: modifiers,
            id: pickHotKeyID,
            into: &pickHotKeyRef,
            label: "⌥⇧S"
        )
        try registerKey(
            keyCode: UInt32(kVK_ANSI_R),
            modifiers: modifiers,
            id: recaptureHotKeyID,
            into: &recaptureHotKeyRef,
            label: "⌥⇧R"
        )
    }

    func unregister() {
        if let pickHotKeyRef {
            UnregisterEventHotKey(pickHotKeyRef)
            self.pickHotKeyRef = nil
        }
        if let recaptureHotKeyRef {
            UnregisterEventHotKey(recaptureHotKeyRef)
            self.recaptureHotKeyRef = nil
        }
        if let handlerRef {
            RemoveEventHandler(handlerRef)
            self.handlerRef = nil
        }
    }

    deinit {
        unregister()
    }

    private func registerKey(
        keyCode: UInt32,
        modifiers: UInt32,
        id: EventHotKeyID,
        into ref: inout EventHotKeyRef?,
        label: String
    ) throws {
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
            unregister()
            throw HotkeyError.register(label, registerStatus)
        }
        ref = hotKeyRef
    }

    enum HotkeyError: LocalizedError {
        case installHandler(OSStatus)
        case register(String, OSStatus)

        var errorDescription: String? {
            switch self {
            case .installHandler(let status):
                return "Failed to install hotkey handler (OSStatus \(status))"
            case .register(let label, let status):
                return "Failed to register \(label) hotkey (OSStatus \(status))"
            }
        }
    }
}
