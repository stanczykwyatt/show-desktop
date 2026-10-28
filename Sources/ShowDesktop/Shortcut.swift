import AppKit
import Carbon.HIToolbox

/// One of the keyboard shortcuts you can pick in the menu.
///
/// A short fixed list instead of a recorder, so a shortcut can never take over plain typing or
/// an everyday command like ⌘D. None of these are used by macOS itself.
struct Shortcut: Equatable, Sendable {
    let id: String
    let keyCode: UInt32
    let modifiers: UInt32
    /// For the menu, such as "⌃⇧D".
    let symbols: String
    let key: String
    let modifierFlags: NSEvent.ModifierFlags

    static let controlShiftD = Shortcut(
        id: "ctrl-shift-d", keyCode: UInt32(kVK_ANSI_D), modifiers: UInt32(controlKey | shiftKey),
        symbols: "⌃⇧D", key: "d", modifierFlags: [.control, .shift]
    )
    static let controlOptionD = Shortcut(
        id: "ctrl-opt-d", keyCode: UInt32(kVK_ANSI_D), modifiers: UInt32(controlKey | optionKey),
        symbols: "⌃⌥D", key: "d", modifierFlags: [.control, .option]
    )
    static let controlOptionCommandD = Shortcut(
        id: "ctrl-opt-cmd-h", keyCode: UInt32(kVK_ANSI_H), modifiers: UInt32(controlKey | optionKey | cmdKey),
        symbols: "⌃⌥⌘H", key: "h", modifierFlags: [.control, .option, .command]
    )

    static let all = [controlShiftD, controlOptionD, controlOptionCommandD]
    static let standard = controlShiftD
}
