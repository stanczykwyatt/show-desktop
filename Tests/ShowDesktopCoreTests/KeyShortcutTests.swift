import Carbon.HIToolbox
import Foundation
import Testing
@testable import ShowDesktopCore

private let control = Modifier.control
private let option = Modifier.option
private let shift = Modifier.shift
private let command = Modifier.command

private func keys(_ keyCode: Int, _ modifiers: UInt32, _ key: String = "X") -> KeyShortcut {
    KeyShortcut(keyCode: UInt32(keyCode), modifiers: modifiers, key: key)
}

@Suite("Shortcut rules")
struct ShortcutRulesTests {
    @Test(arguments: [
        keys(kVK_ANSI_D, control | shift, "D"),
        keys(kVK_ANSI_D, control | option, "D"),
        keys(kVK_ANSI_H, control | option | command, "H"),
        keys(kVK_ANSI_D, control, "D"),
        keys(kVK_ANSI_E, option | command, "E"),
        keys(kVK_ANSI_D, command | shift, "D"),
        keys(kVK_ANSI_D, option | shift | command, "D"),
        keys(kVK_Space, control | shift, "Space"),
        keys(kVK_Return, control | option, "↩"),
        keys(kVK_UpArrow, control | option, "↑"),
        keys(kVK_ANSI_1, control | shift, "1"),
        keys(kVK_ANSI_Semicolon, control | shift, ";"),
    ])
    func acceptsShortcutsThatLeaveTypingAlone(_ shortcut: KeyShortcut) {
        #expect(ShortcutRules.problem(with: shortcut) == nil)
    }

    @Test(arguments: [
        keys(kVK_ANSI_D, 0, "D"),
        keys(kVK_ANSI_D, shift, "D"),
        keys(kVK_ANSI_C, command, "C"),
        keys(kVK_ANSI_V, command, "V"),
        keys(kVK_ANSI_Q, command, "Q"),
        // Option and Shift-Option type characters like ∂, é and Ø.
        keys(kVK_ANSI_D, option, "D"),
        keys(kVK_ANSI_E, option, "E"),
        keys(kVK_ANSI_O, option | shift, "O"),
        keys(kVK_Space, 0, "Space"),
        keys(kVK_Space, option, "Space"),
        keys(kVK_Return, 0, "↩"),
        keys(kVK_Tab, 0, "⇥"),
        keys(kVK_Delete, command, "⌫"),
        keys(kVK_LeftArrow, 0, "←"),
        keys(kVK_LeftArrow, option, "←"),
    ])
    func refusesShortcutsThatTakeOverTyping(_ shortcut: KeyShortcut) {
        #expect(ShortcutRules.problem(with: shortcut) == .needsModifier)
    }

    @Test(arguments: [
        keys(kVK_ANSI_3, command | shift, "3"),
        keys(kVK_ANSI_4, command | shift, "4"),
        keys(kVK_ANSI_5, command | shift, "5"),
        keys(kVK_ANSI_4, control | command | shift, "4"),
        keys(kVK_ANSI_Q, control | command, "Q"),
        keys(kVK_ANSI_Q, command | shift, "Q"),
        keys(kVK_Escape, option | command, "⎋"),
        keys(kVK_ANSI_D, option | command, "D"),
        keys(kVK_Space, control, "Space"),
        keys(kVK_Space, control | command, "Space"),
        keys(kVK_UpArrow, control, "↑"),
        keys(kVK_RightArrow, control, "→"),
        keys(kVK_Tab, control, "⇥"),
        keys(kVK_ANSI_F, control | command, "F"),
        keys(kVK_ANSI_H, option | command, "H"),
        keys(kVK_ANSI_Z, command | shift, "Z"),
        keys(kVK_ANSI_T, command | shift, "T"),
    ])
    func refusesShortcutsMacOSAndMostAppsUse(_ shortcut: KeyShortcut) {
        #expect(ShortcutRules.problem(with: shortcut) == .alreadyUsed)
    }

    @Test func functionKeysWorkOnTheirOwn() {
        for keyCode in [kVK_F1, kVK_F5, kVK_F12, kVK_F13, kVK_F19, kVK_F20] {
            #expect(ShortcutRules.problem(with: keys(keyCode, 0, "F")) == nil)
            #expect(ShortcutRules.problem(with: keys(keyCode, shift, "F")) == nil)
        }
    }

    @Test func thePresetsAreAllAllowed() {
        for preset in KeyShortcut.presets {
            #expect(ShortcutRules.problem(with: preset) == nil)
        }
    }

    @Test func extraModifierBitsAreDropped() {
        // Caps Lock and Carbon's active flag aren't shortcut modifiers.
        let shortcut = KeyShortcut(keyCode: UInt32(kVK_ANSI_D), modifiers: control | shift | UInt32(alphaLock) | UInt32(activeFlag), key: "D")
        #expect(shortcut.modifiers == control | shift)
        #expect(shortcut.hasSameKeys(as: .controlShiftD))
    }
}

@Suite("Shortcut labels")
struct ShortcutLabelTests {
    @Test func listsModifiersInTheOrderMacOSUses() {
        #expect(keys(kVK_ANSI_H, command | shift | option | control, "H").displayString == "⌃⌥⇧⌘H")
        #expect(KeyShortcut.controlShiftD.displayString == "⌃⇧D")
        #expect(KeyShortcut.controlOptionCommandH.displayString == "⌃⌥⌘H")
        #expect(keys(kVK_F5, 0, "F5").displayString == "F5")
    }

    @Test func numbersTheFunctionKeys() {
        #expect(keys(kVK_F1, 0).functionKeyNumber == 1)
        #expect(keys(kVK_F11, 0).functionKeyNumber == 11)
        #expect(keys(kVK_F20, 0).functionKeyNumber == 20)
        #expect(keys(kVK_ANSI_F, 0).functionKeyNumber == nil)
    }

    @Test func comparesKeysNotLabels() {
        // The same physical key reads differently on other keyboard layouts.
        let german = KeyShortcut(keyCode: UInt32(kVK_ANSI_Y), modifiers: control | shift, key: "Z")
        let english = KeyShortcut(keyCode: UInt32(kVK_ANSI_Y), modifiers: control | shift, key: "Y")
        #expect(german.hasSameKeys(as: english))
        #expect(!german.hasSameKeys(as: KeyShortcut(keyCode: UInt32(kVK_ANSI_Y), modifiers: control, key: "Y")))
    }
}

@Suite("Recording a shortcut")
struct RecordedKeyTests {
    @Test func escapeCancels() {
        #expect(RecordedKey.from(keyCode: UInt32(kVK_Escape), modifiers: 0, key: "⎋") == .cancel)
    }

    @Test func escapeWithModifiersIsJudgedLikeAnyOtherKey() {
        #expect(RecordedKey.from(keyCode: UInt32(kVK_Escape), modifiers: option | command, key: "⎋") == .refuse(.alreadyUsed))
        #expect(RecordedKey.from(keyCode: UInt32(kVK_Escape), modifiers: control | shift, key: "⎋")
            == .use(keys(kVK_Escape, control | shift, "⎋")))
    }

    @Test func usesAnAllowedShortcut() {
        #expect(RecordedKey.from(keyCode: UInt32(kVK_ANSI_D), modifiers: option | command, key: "D") == .refuse(.alreadyUsed))
        #expect(RecordedKey.from(keyCode: UInt32(kVK_ANSI_E), modifiers: option | command, key: "E")
            == .use(keys(kVK_ANSI_E, option | command, "E")))
    }

    @Test func refusesPlainTyping() {
        #expect(RecordedKey.from(keyCode: UInt32(kVK_ANSI_A), modifiers: 0, key: "A") == .refuse(.needsModifier))
        #expect(RecordedKey.from(keyCode: UInt32(kVK_ANSI_A), modifiers: option, key: "A") == .refuse(.needsModifier))
    }

    @Test func refusesKeysWithoutALabel() {
        #expect(RecordedKey.from(keyCode: UInt32(kVK_ANSI_A), modifiers: control | shift, key: nil) == .refuse(.needsModifier))
        #expect(RecordedKey.from(keyCode: UInt32(kVK_ANSI_A), modifiers: control | shift, key: "") == .refuse(.needsModifier))
    }

    @Test func refusesKeyCodesNoKeyboardSends() {
        #expect(RecordedKey.from(keyCode: 200, modifiers: control | shift, key: "?") == .refuse(.needsModifier))
    }
}

/// Settings kept in memory, so tests never touch real preferences.
private final class MemoryStorage: SettingsStorage {
    private var values: [String: Any] = [:]

    func string(forKey defaultName: String) -> String? { values[defaultName] as? String }
    func data(forKey defaultName: String) -> Data? { values[defaultName] as? Data }
    func set(_ value: Any?, forKey defaultName: String) { values[defaultName] = value }
    func removeObject(forKey defaultName: String) { values[defaultName] = nil }
}

@Suite("Saving the shortcut")
struct ShortcutStoreTests {
    private func freshDefaults() -> MemoryStorage {
        MemoryStorage()
    }

    @Test func defaultsToControlShiftD() {
        #expect(ShortcutStore(defaults: freshDefaults()).shortcut == .controlShiftD)
    }

    @Test func readsTheChoicesSavedByVersion010() {
        let defaults = freshDefaults()
        let store = ShortcutStore(defaults: defaults)
        defaults.set("ctrl-opt-d", forKey: "shortcut")
        #expect(store.shortcut == .controlOptionD)
        defaults.set("ctrl-opt-cmd-h", forKey: "shortcut")
        #expect(store.shortcut == .controlOptionCommandH)
        defaults.set("ctrl-shift-d", forKey: "shortcut")
        #expect(store.shortcut == .controlShiftD)
        defaults.set("", forKey: "shortcut")
        #expect(store.shortcut == nil)
    }

    @Test func savesPresetsTheWayVersion010Did() {
        let defaults = freshDefaults()
        let store = ShortcutStore(defaults: defaults)
        store.shortcut = .controlOptionD
        #expect(defaults.string(forKey: "shortcut") == "ctrl-opt-d")
        #expect(defaults.data(forKey: "customShortcut") == nil)

        // A recorded shortcut that matches a preset is saved as that preset.
        store.shortcut = KeyShortcut(keyCode: UInt32(kVK_ANSI_H), modifiers: control | option | command, key: "H")
        #expect(defaults.string(forKey: "shortcut") == "ctrl-opt-cmd-h")
    }

    @Test func savesARecordedShortcut() {
        let defaults = freshDefaults()
        let store = ShortcutStore(defaults: defaults)
        let recorded = keys(kVK_F13, 0, "F13")
        store.shortcut = recorded
        #expect(defaults.string(forKey: "shortcut") == "custom")
        #expect(store.shortcut == recorded)
        #expect(ShortcutStore(defaults: defaults).shortcut == recorded)
    }

    @Test func turningItOffForgetsTheRecordedShortcut() {
        let defaults = freshDefaults()
        let store = ShortcutStore(defaults: defaults)
        store.shortcut = keys(kVK_ANSI_E, option | command, "E")
        store.shortcut = nil
        #expect(store.shortcut == nil)
        #expect(defaults.string(forKey: "shortcut") == "")
        #expect(defaults.data(forKey: "customShortcut") == nil)
    }

    @Test func switchingToAPresetForgetsTheRecordedShortcut() {
        let defaults = freshDefaults()
        let store = ShortcutStore(defaults: defaults)
        store.shortcut = keys(kVK_ANSI_E, option | command, "E")
        store.shortcut = .controlShiftD
        #expect(defaults.data(forKey: "customShortcut") == nil)
        #expect(store.shortcut == .controlShiftD)
    }

    @Test func fallsBackToTheDefaultWhenSavedDataIsDamaged() throws {
        let defaults = freshDefaults()
        let store = ShortcutStore(defaults: defaults)
        defaults.set("custom", forKey: "shortcut")
        #expect(store.shortcut == .controlShiftD)

        defaults.set(Data("not json".utf8), forKey: "customShortcut")
        #expect(store.shortcut == .controlShiftD)

        defaults.set(Data(#"{"keyCode":2}"#.utf8), forKey: "customShortcut")
        #expect(store.shortcut == .controlShiftD)

        defaults.set("a name from a newer version", forKey: "shortcut")
        #expect(store.shortcut == .controlShiftD)
    }

    @Test func neverRegistersAShortcutTheRecorderWouldRefuse() throws {
        let defaults = freshDefaults()
        let store = ShortcutStore(defaults: defaults)
        defaults.set("custom", forKey: "shortcut")
        for unsafe in [keys(kVK_ANSI_C, command, "C"), keys(kVK_ANSI_E, option, "E"), keys(kVK_ANSI_3, command | shift, "3"),
                       keys(500, control | shift, "?"), keys(kVK_ANSI_D, control | shift, "")] {
            defaults.set(try JSONEncoder().encode(unsafe), forKey: "customShortcut")
            #expect(store.shortcut == .controlShiftD)
        }
    }

    @Test func dropsStrayModifierBitsFromSavedData() throws {
        let defaults = freshDefaults()
        let store = ShortcutStore(defaults: defaults)
        defaults.set("custom", forKey: "shortcut")
        let json = #"{"keyCode":\#(kVK_ANSI_E),"modifiers":\#(option | command | 0x4000_0000),"key":"E"}"#
        defaults.set(Data(json.utf8), forKey: "customShortcut")
        #expect(store.shortcut == keys(kVK_ANSI_E, option | command, "E"))
    }
}
