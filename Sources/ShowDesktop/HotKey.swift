import Carbon.HIToolbox

/// A system-wide keyboard shortcut.
///
/// Uses the Carbon hot key API, which only reports the shortcut that was
/// registered. Show Desktop never needs Accessibility or Input Monitoring
/// permission and never sees anything else you type.
@MainActor
final class HotKey {
    var onPress: () -> Void = {}
    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?

    init() {
        var pressed = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, _, context in
            guard let context else { return OSStatus(eventNotHandledErr) }
            let hotKey = Unmanaged<HotKey>.fromOpaque(context).takeUnretainedValue()
            // Carbon delivers hot key events on the main thread.
            MainActor.assumeIsolated { hotKey.onPress() }
            return noErr
        }, 1, &pressed, Unmanaged.passUnretained(self).toOpaque(), &handlerRef)
    }

    /// Returns false if another app already uses the shortcut.
    @discardableResult
    func register(_ shortcut: Shortcut) -> Bool {
        unregister()
        let hotKeyID = EventHotKeyID(signature: OSType(0x5348_4454), id: 1)  // "SHDT"
        let status = RegisterEventHotKey(shortcut.keyCode, shortcut.modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
        return status == noErr
    }

    func unregister() {
        guard let hotKeyRef else { return }
        UnregisterEventHotKey(hotKeyRef)
        self.hotKeyRef = nil
    }
}
