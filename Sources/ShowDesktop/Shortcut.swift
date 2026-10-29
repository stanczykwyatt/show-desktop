import AppKit
import Carbon.HIToolbox
import ShowDesktopCore

extension KeyShortcut {
    /// What a key press means while a shortcut is being recorded.
    static func recorded(from event: NSEvent) -> RecordedKey {
        RecordedKey.from(keyCode: UInt32(event.keyCode), modifiers: carbonModifiers(event.modifierFlags), key: label(for: event))
    }

    static func carbonModifiers(_ flags: NSEvent.ModifierFlags) -> UInt32 {
        let flags = flags.intersection(.deviceIndependentFlagsMask)
        var modifiers: UInt32 = 0
        if flags.contains(.control) { modifiers |= Modifier.control }
        if flags.contains(.option) { modifiers |= Modifier.option }
        if flags.contains(.shift) { modifiers |= Modifier.shift }
        if flags.contains(.command) { modifiers |= Modifier.command }
        return modifiers
    }

    /// The key's label as printed on the keyboard, in the current keyboard layout.
    /// Nil for a key that can't be part of a shortcut.
    static func label(for event: NSEvent) -> String? {
        if let named = namedKeys[Int(event.keyCode)] {
            return named.label
        }
        // The key's own label, without Shift or Option changing it into another character.
        guard let scalar = event.characters(byApplyingModifiers: [])?.unicodeScalars.first else { return nil }
        let properties = scalar.properties
        guard properties.isAlphabetic || properties.numericType != nil || properties.generalCategory.isPunctuationOrSymbol else {
            return nil
        }
        return String(scalar).uppercased()
    }

    /// The shortcut as a menu key equivalent, so the menu can show it next to Show Desktop.
    var menuKeyEquivalent: (key: String, modifiers: NSEvent.ModifierFlags)? {
        var flags: NSEvent.ModifierFlags = []
        if modifiers & Modifier.control != 0 { flags.insert(.control) }
        if modifiers & Modifier.option != 0 { flags.insert(.option) }
        if modifiers & Modifier.shift != 0 { flags.insert(.shift) }
        if modifiers & Modifier.command != 0 { flags.insert(.command) }
        if let named = Self.namedKeys[Int(keyCode)] {
            return (named.menuKey, flags)
        }
        guard key.count == 1, key.first?.isASCII == true else { return nil }
        return (key.lowercased(), flags)
    }

    /// Keys whose label isn't the character they type, with the key menus use for each.
    private static let namedKeys: [Int: (label: String, menuKey: String)] = {
        var keys: [Int: (label: String, menuKey: String)] = [
            kVK_Space: ("Space", " "),
            kVK_Return: ("↩", "\r"),
            kVK_ANSI_KeypadEnter: ("⌤", "\u{3}"),
            kVK_Tab: ("⇥", "\t"),
            kVK_Delete: ("⌫", "\u{8}"),
            kVK_ForwardDelete: ("⌦", function(NSDeleteFunctionKey)),
            kVK_Escape: ("⎋", "\u{1b}"),
            kVK_LeftArrow: ("←", function(NSLeftArrowFunctionKey)),
            kVK_RightArrow: ("→", function(NSRightArrowFunctionKey)),
            kVK_UpArrow: ("↑", function(NSUpArrowFunctionKey)),
            kVK_DownArrow: ("↓", function(NSDownArrowFunctionKey)),
            kVK_Home: ("↖", function(NSHomeFunctionKey)),
            kVK_End: ("↘", function(NSEndFunctionKey)),
            kVK_PageUp: ("⇞", function(NSPageUpFunctionKey)),
            kVK_PageDown: ("⇟", function(NSPageDownFunctionKey)),
        ]
        let functionKeys = [
            kVK_F1, kVK_F2, kVK_F3, kVK_F4, kVK_F5, kVK_F6, kVK_F7, kVK_F8, kVK_F9, kVK_F10,
            kVK_F11, kVK_F12, kVK_F13, kVK_F14, kVK_F15, kVK_F16, kVK_F17, kVK_F18, kVK_F19, kVK_F20,
        ]
        for (index, keyCode) in functionKeys.enumerated() {
            keys[keyCode] = ("F\(index + 1)", function(NSF1FunctionKey + index))
        }
        return keys
    }()

    private static func function(_ key: Int) -> String {
        String(Character(UnicodeScalar(UInt16(key))!))
    }
}

private extension Unicode.GeneralCategory {
    var isPunctuationOrSymbol: Bool {
        switch self {
        case .connectorPunctuation, .dashPunctuation, .openPunctuation, .closePunctuation,
             .initialPunctuation, .finalPunctuation, .otherPunctuation,
             .mathSymbol, .currencySymbol, .modifierSymbol, .otherSymbol:
            true
        default:
            false
        }
    }
}
