import Carbon
import Foundation

protocol RegisteredKeyHotkeyListening: AnyObject {
    func stop()
}

/// A bare-key shortcut owned by the macOS hotkey dispatcher. All lifecycle
/// calls and callbacks run on the main thread; no global keyboard tap is used.
final class RegisteredKeyHotkey: RegisteredKeyHotkeyListening {
    typealias Factory = (UInt16, @escaping (Bool) -> Void) -> RegisteredKeyHotkeyListening?

    private var hotkey: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private let keyID: EventHotKeyID
    private let onChange: (Bool) -> Void

    private init(keyCode: UInt16, onChange: @escaping (Bool) -> Void) {
        keyID = EventHotKeyID(signature: 0x4A6F744B, id: UInt32(keyCode))  // JotK
        self.onChange = onChange
    }

    static func start(keyCode: UInt16, onChange: @escaping (Bool) -> Void) -> RegisteredKeyHotkeyListening? {
        precondition(Thread.isMainThread)
        let listener = RegisteredKeyHotkey(keyCode: keyCode, onChange: onChange)
        var types = [
            EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed)),
            EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyReleased)),
        ]
        let installed = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, context in
                guard let event, let context else { return OSStatus(eventNotHandledErr) }
                let listener = Unmanaged<RegisteredKeyHotkey>.fromOpaque(context).takeUnretainedValue()
                var keyID = EventHotKeyID()
                let status = GetEventParameter(
                    event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID),
                    nil, MemoryLayout<EventHotKeyID>.size, nil, &keyID
                )
                guard status == noErr,
                    keyID.signature == listener.keyID.signature, keyID.id == listener.keyID.id
                else { return OSStatus(eventNotHandledErr) }
                listener.onChange(GetEventKind(event) == UInt32(kEventHotKeyPressed))
                return noErr
            },
            types.count, &types, Unmanaged.passUnretained(listener).toOpaque(), &listener.eventHandler
        )
        guard installed == noErr else { return nil }
        let registered = RegisterEventHotKey(
            UInt32(keyCode), 0, listener.keyID, GetApplicationEventTarget(), 0, &listener.hotkey
        )
        guard registered == noErr else {
            listener.stop()
            return nil
        }
        return listener
    }

    func stop() {
        precondition(Thread.isMainThread)
        if let hotkey { UnregisterEventHotKey(hotkey) }
        hotkey = nil
        if let eventHandler { RemoveEventHandler(eventHandler) }
        eventHandler = nil
    }

    deinit { stop() }
}
