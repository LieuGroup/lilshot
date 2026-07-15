import AppKit
import Carbon.HIToolbox

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
        try registerKey(UInt32(kVK_ANSI_S), modifiers, pickHotKeyID, &pickHotKeyRef, "⌥⇧S")
        try registerKey(UInt32(kVK_ANSI_R), modifiers, recaptureHotKeyID, &recaptureHotKeyRef, "⌥⇧R")
        try registerKey(UInt32(kVK_ANSI_F), modifiers, fullscreenHotKeyID, &fullscreenHotKeyRef, "⌥⇧F")
        try registerKey(UInt32(kVK_ANSI_A), modifiers, regionHotKeyID, &regionHotKeyRef, "⌥⇧A")
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

    private func registerKey(
        _ keyCode: UInt32,
        _ modifiers: UInt32,
        _ id: EventHotKeyID,
        _ ref: inout EventHotKeyRef?,
        _ label: String
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
