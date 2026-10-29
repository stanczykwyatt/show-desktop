import Carbon.HIToolbox
import Foundation

/// A keyboard shortcut, stored as the Carbon key code and modifier mask that
/// `RegisterEventHotKey` expects.
public struct KeyShortcut: Codable, Hashable, Sendable {
    public var keyCode: UInt32
    public var modifiers: UInt32
    /// The key's label as printed on the keyboard, such as "D" or "F5".
    public var key: String

    public init(keyCode: UInt32, modifiers: UInt32, key: String) {
        self.keyCode = keyCode
        self.modifiers = modifiers & Modifier.all
        self.key = key
    }

    private enum CodingKeys: String, CodingKey {
        case keyCode, modifiers, key
    }

    /// Decodes through `init(keyCode:modifiers:key:)`, so saved modifiers can't carry stray bits.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            keyCode: try container.decode(UInt32.self, forKey: .keyCode),
            modifiers: try container.decode(UInt32.self, forKey: .modifiers),
            key: try container.decode(String.self, forKey: .key)
        )
    }

    /// Mac key codes go from 0 to 127.
    public var isValidKey: Bool {
        keyCode < 128 && !key.isEmpty
    }

    public static let controlShiftD = KeyShortcut(keyCode: UInt32(kVK_ANSI_D), modifiers: Modifier.control | Modifier.shift, key: "D")
    public static let controlOptionD = KeyShortcut(keyCode: UInt32(kVK_ANSI_D), modifiers: Modifier.control | Modifier.option, key: "D")
    public static let controlOptionCommandH = KeyShortcut(
        keyCode: UInt32(kVK_ANSI_H), modifiers: Modifier.control | Modifier.option | Modifier.command, key: "H"
    )

    /// The shortcuts offered in the menu. None of them are used by macOS itself.
    public static let presets = [controlShiftD, controlOptionD, controlOptionCommandH]
    public static let standard = controlShiftD

    /// Whether both use the same physical key and modifiers. The printed label is ignored,
    /// since the same key is labeled differently on other keyboard layouts.
    public func hasSameKeys(as other: KeyShortcut) -> Bool {
        keyCode == other.keyCode && modifiers == other.modifiers
    }

    /// For menus and messages, such as "⌃⇧D". Modifiers are in the order macOS shows them.
    public var displayString: String {
        var text = ""
        if modifiers & Modifier.control != 0 { text += "⌃" }
        if modifiers & Modifier.option != 0 { text += "⌥" }
        if modifiers & Modifier.shift != 0 { text += "⇧" }
        if modifiers & Modifier.command != 0 { text += "⌘" }
        return text + key
    }

    /// 1 to 20 for the function keys F1 to F20, otherwise nil.
    public var functionKeyNumber: Int? {
        Self.functionKeys[Int(keyCode)]
    }

    private static let functionKeys: [Int: Int] = [
        kVK_F1: 1, kVK_F2: 2, kVK_F3: 3, kVK_F4: 4, kVK_F5: 5, kVK_F6: 6, kVK_F7: 7,
        kVK_F8: 8, kVK_F9: 9, kVK_F10: 10, kVK_F11: 11, kVK_F12: 12, kVK_F13: 13, kVK_F14: 14,
        kVK_F15: 15, kVK_F16: 16, kVK_F17: 17, kVK_F18: 18, kVK_F19: 19, kVK_F20: 20,
    ]
}

/// Carbon's modifier masks, which are what `RegisterEventHotKey` takes.
public enum Modifier {
    public static let control = UInt32(controlKey)
    public static let option = UInt32(optionKey)
    public static let shift = UInt32(shiftKey)
    public static let command = UInt32(cmdKey)
    public static let all = control | option | shift | command
}

/// Why a shortcut can't be used.
public enum ShortcutProblem: Equatable, Sendable {
    /// It would take over plain typing, a typed character like ⌥E, or an everyday command like ⌘C.
    case needsModifier
    /// macOS or nearly every app already uses it, like ⌘⇧3 for screenshots or ⌘⇧Z for Redo.
    case alreadyUsed
}

public enum ShortcutRules {
    /// Returns why a shortcut can't be used, or nil if it can.
    ///
    /// Function keys work on their own. Every other key needs ⌃, or ⌘ together with ⇧ or ⌥.
    /// ⌥ and ⇧ alone aren't enough, since they type characters like é, ∂ and capital letters.
    public static func problem(with shortcut: KeyShortcut) -> ShortcutProblem? {
        let modifiers = shortcut.modifiers
        let hasControl = modifiers & Modifier.control != 0
        let hasCommand = modifiers & Modifier.command != 0
        let hasShiftOrOption = modifiers & (Modifier.shift | Modifier.option) != 0
        guard shortcut.functionKeyNumber != nil || hasControl || (hasCommand && hasShiftOrOption) else {
            return .needsModifier
        }
        if reserved.contains(where: { $0.keyCode == shortcut.keyCode && $0.modifiers == modifiers }) {
            return .alreadyUsed
        }
        return nil
    }

    private struct Keys {
        let keyCode: UInt32
        let modifiers: UInt32

        init(_ keyCode: Int, _ modifiers: UInt32) {
            self.keyCode = UInt32(keyCode)
            self.modifiers = modifiers
        }
    }

    /// Shortcuts that macOS uses, or that almost every app uses for an everyday command.
    /// A global shortcut would take these over everywhere, so they're refused.
    private static let reserved: [Keys] = {
        let control = Modifier.control, option = Modifier.option, shift = Modifier.shift, command = Modifier.command
        return [
            // Screenshots and screen recording.
            Keys(kVK_ANSI_3, command | shift), Keys(kVK_ANSI_4, command | shift),
            Keys(kVK_ANSI_5, command | shift), Keys(kVK_ANSI_6, command | shift),
            Keys(kVK_ANSI_3, control | command | shift), Keys(kVK_ANSI_4, control | command | shift),
            // Log out, lock the screen and force quit.
            Keys(kVK_ANSI_Q, command | shift), Keys(kVK_ANSI_Q, option | command | shift),
            Keys(kVK_ANSI_Q, control | command), Keys(kVK_Escape, option | command),
            // The Dock, Spotlight, input sources, and emoji and symbols.
            Keys(kVK_ANSI_D, option | command), Keys(kVK_Space, option | command),
            Keys(kVK_Space, control), Keys(kVK_Space, control | option), Keys(kVK_Space, control | command),
            // Mission Control, App Exposé and switching between Spaces.
            Keys(kVK_UpArrow, control), Keys(kVK_DownArrow, control),
            Keys(kVK_LeftArrow, control), Keys(kVK_RightArrow, control),
            // Switching apps and tabs.
            Keys(kVK_Tab, command | shift), Keys(kVK_Tab, control), Keys(kVK_Tab, control | shift),
            Keys(kVK_ANSI_LeftBracket, command | shift), Keys(kVK_ANSI_RightBracket, command | shift),
            // Full screen, hide others, minimize all and close all.
            Keys(kVK_ANSI_F, control | command), Keys(kVK_ANSI_H, option | command),
            Keys(kVK_ANSI_M, option | command), Keys(kVK_ANSI_W, option | command),
            // Redo, Save As, new window or folder, reopen tab, find previous, help and hidden files.
            Keys(kVK_ANSI_Z, command | shift), Keys(kVK_ANSI_S, command | shift),
            Keys(kVK_ANSI_N, command | shift), Keys(kVK_ANSI_T, command | shift),
            Keys(kVK_ANSI_G, command | shift), Keys(kVK_ANSI_Slash, command | shift),
            Keys(kVK_ANSI_Period, command | shift),
        ]
    }()
}

/// What a key press does while a new shortcut is being recorded.
public enum RecordedKey: Equatable, Sendable {
    /// Escape stops recording without changing anything.
    case cancel
    case refuse(ShortcutProblem)
    case use(KeyShortcut)

    /// `key` is the pressed key's label, or nil for a key that can't be part of a shortcut.
    public static func from(keyCode: UInt32, modifiers: UInt32, key: String?) -> RecordedKey {
        if keyCode == UInt32(kVK_Escape) && modifiers & Modifier.all == 0 {
            return .cancel
        }
        guard let key else { return .refuse(.needsModifier) }
        let shortcut = KeyShortcut(keyCode: keyCode, modifiers: modifiers, key: key)
        guard shortcut.isValidKey else { return .refuse(.needsModifier) }
        if let problem = ShortcutRules.problem(with: shortcut) {
            return .refuse(problem)
        }
        return .use(shortcut)
    }
}

/// The parts of `UserDefaults` the app uses, so tests can keep settings in memory instead.
public protocol SettingsStorage: AnyObject {
    func string(forKey defaultName: String) -> String?
    func data(forKey defaultName: String) -> Data?
    func set(_ value: Any?, forKey defaultName: String)
    func removeObject(forKey defaultName: String)
}

extension UserDefaults: SettingsStorage {}

/// Keeps the chosen shortcut in the app's preferences.
///
/// Version 0.1.0 saved the name of a preset, or an empty string for no shortcut. A recorded
/// shortcut is saved as "custom" with its keys next to it, so a preset picked in 0.1.0 carries
/// over unchanged.
public struct ShortcutStore {
    private let defaults: any SettingsStorage

    public init(defaults: any SettingsStorage = UserDefaults.standard) {
        self.defaults = defaults
    }

    static let choiceKey = "shortcut"
    static let customKey = "customShortcut"
    static let custom = "custom"
    static let presetNames: [(name: String, shortcut: KeyShortcut)] = [
        ("ctrl-shift-d", .controlShiftD),
        ("ctrl-opt-d", .controlOptionD),
        ("ctrl-opt-cmd-h", .controlOptionCommandH),
    ]

    /// Nil means the shortcut is turned off.
    public var shortcut: KeyShortcut? {
        get {
            // Nothing saved means the default. An empty string means it was turned off.
            guard let choice = defaults.string(forKey: Self.choiceKey) else { return .standard }
            if choice.isEmpty { return nil }
            if choice == Self.custom {
                // Damaged or hand-edited preferences never register a shortcut the recorder would refuse.
                guard let data = defaults.data(forKey: Self.customKey),
                      let saved = try? JSONDecoder().decode(KeyShortcut.self, from: data),
                      saved.isValidKey, ShortcutRules.problem(with: saved) == nil else { return .standard }
                return saved
            }
            return Self.presetNames.first { $0.name == choice }?.shortcut ?? .standard
        }
        nonmutating set {
            guard let newValue else {
                defaults.set("", forKey: Self.choiceKey)
                defaults.removeObject(forKey: Self.customKey)
                return
            }
            if let preset = Self.presetNames.first(where: { $0.shortcut.hasSameKeys(as: newValue) }) {
                defaults.set(preset.name, forKey: Self.choiceKey)
                defaults.removeObject(forKey: Self.customKey)
            } else {
                defaults.set(try? JSONEncoder().encode(newValue), forKey: Self.customKey)
                defaults.set(Self.custom, forKey: Self.choiceKey)
            }
        }
    }
}
