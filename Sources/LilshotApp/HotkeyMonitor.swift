import AppKit
import Carbon.HIToolbox

/// Global ⌥⇧S via Carbon `RegisterEventHotKey` — no third-party deps.
final class HotkeyMonitor: @unchecked Sendable {
    var onHotkey: (() -> Void)?

    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?
    private let hotKeyID = EventHotKeyID(
        signature: OSType(0x4C53484B), // "LSHK"
        id: 1
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
                guard err == noErr, eventHotKeyID.id == monitor.hotKeyID.id else {
                    return OSStatus(eventNotHandledErr)
                }
                monitor.onHotkey?()
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

        var hotKeyRef: EventHotKeyRef?
        let modifiers = UInt32(optionKey | shiftKey)
        let keyCode = UInt32(kVK_ANSI_S)
        let registerStatus = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        guard registerStatus == noErr else {
            unregister()
            throw HotkeyError.register(registerStatus)
        }
        self.hotKeyRef = hotKeyRef
    }

    func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        if let handlerRef {
            RemoveEventHandler(handlerRef)
            self.handlerRef = nil
        }
    }

    deinit {
        unregister()
    }

    enum HotkeyError: LocalizedError {
        case installHandler(OSStatus)
        case register(OSStatus)

        var errorDescription: String? {
            switch self {
            case .installHandler(let status):
                return "Failed to install hotkey handler (OSStatus \(status))"
            case .register(let status):
                return "Failed to register ⌥⇧S hotkey (OSStatus \(status))"
            }
        }
    }
}
