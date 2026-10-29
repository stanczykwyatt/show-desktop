import AppKit
import ServiceManagement
import ShowDesktopCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let controller = DesktopController()
    private let hotKey = HotKey()
    private let recorder = ShortcutRecorder()
    private let shortcutStore = ShortcutStore()
    /// Whether another app already had the shortcut when Show Desktop tried to use it.
    private var shortcutIsTaken = false
    private let defaults = UserDefaults.standard
    private var statusItem: NSStatusItem!
    private let menu = NSMenu()

    private enum Key {
        static let minimizesFinderWindows = "minimizesFinderWindows"
        static let launchedBefore = "launchedBefore"
    }

    /// Nil when the shortcut is turned off.
    private var shortcut: KeyShortcut? {
        get { shortcutStore.shortcut }
        set { shortcutStore.shortcut = newValue }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        defaults.register(defaults: [Key.minimizesFinderWindows: true])
        controller.minimizesFinderWindows = defaults.bool(forKey: Key.minimizesFinderWindows)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "macwindow.on.rectangle", accessibilityDescription: "Show Desktop")
            button.toolTip = "Show Desktop: click to hide every window, click again to bring them back. Right-click for options."
            button.target = self
            button.action = #selector(statusItemClicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        menu.delegate = self

        hotKey.onPress = { [weak self] in self?.toggle() }
        recorder.onRecord = { [weak self] recorded in self?.useRecordedShortcut(recorded) ?? false }
        recorder.onClose = { [weak self] in
            self?.registerShortcut()
            // Gives the keyboard back to the app you were using.
            NSApp.hide(nil)
        }
        registerShortcut()

        // Open at login by default the first time, like most menu bar utilities. You can turn it off in the menu.
        if !defaults.bool(forKey: Key.launchedBefore) {
            defaults.set(true, forKey: Key.launchedBefore)
            try? SMAppService.mainApp.register()
        }
    }

    private func toggle() {
        controller.toggle()
        statusItem.button?.image = NSImage(
            systemSymbolName: controller.isShowingDesktop ? "macwindow.badge.plus" : "macwindow.on.rectangle",
            accessibilityDescription: controller.isShowingDesktop ? "Bring windows back" : "Show Desktop"
        )
    }

    private func registerShortcut() {
        hotKey.unregister()
        shortcutIsTaken = false
        // While recording, the current shortcut stays free so it can be typed into the recorder.
        guard !recorder.isShown, let shortcut else { return }
        shortcutIsTaken = !hotKey.register(shortcut)
    }

    /// Saves a recorded shortcut if it can be registered. Returns false if another app has it.
    private func useRecordedShortcut(_ recorded: KeyShortcut) -> Bool {
        guard hotKey.register(recorded) else { return false }
        shortcut = recorded
        shortcutIsTaken = false
        return true
    }

    // MARK: Status item

    /// A click toggles the Desktop. A right-click or Control-click opens the menu.
    @objc private func statusItemClicked() {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp || event?.modifierFlags.contains(.control) == true {
            statusItem.menu = menu
            statusItem.button?.performClick(nil)
            statusItem.menu = nil
        } else {
            toggle()
        }
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        // A shortcut another app took doesn't work, so the menu doesn't show it.
        let equivalent = shortcutIsTaken ? nil : shortcut?.menuKeyEquivalent
        let toggleItem = NSMenuItem(
            title: controller.isShowingDesktop ? "Bring Windows Back" : "Show Desktop",
            action: #selector(toggleFromMenu), keyEquivalent: equivalent?.key ?? ""
        )
        toggleItem.keyEquivalentModifierMask = equivalent?.modifiers ?? []
        toggleItem.target = self
        menu.addItem(toggleItem)
        menu.addItem(.separator())

        let shortcuts = NSMenu()
        if shortcutIsTaken, let shortcut {
            let warning = NSMenuItem(title: "Another app is using \(shortcut.displayString)", action: nil, keyEquivalent: "")
            warning.image = NSImage(systemSymbolName: "exclamationmark.triangle", accessibilityDescription: "Warning")
            warning.isEnabled = false
            shortcuts.addItem(warning)
            shortcuts.addItem(.separator())
        }
        var options = KeyShortcut.presets
        if let shortcut, !options.contains(where: { $0.hasSameKeys(as: shortcut) }) {
            options.append(shortcut)
        }
        for option in options {
            let item = NSMenuItem(title: option.displayString, action: #selector(chooseShortcut(_:)), keyEquivalent: "")
            item.representedObject = option
            item.state = shortcut.map(option.hasSameKeys(as:)) == true ? .on : .off
            item.target = self
            shortcuts.addItem(item)
        }
        shortcuts.addItem(.separator())
        let record = NSMenuItem(title: "Record Shortcut…", action: #selector(recordShortcut), keyEquivalent: "")
        record.target = self
        shortcuts.addItem(record)
        let off = NSMenuItem(title: "None", action: #selector(chooseShortcut(_:)), keyEquivalent: "")
        off.state = shortcut == nil ? .on : .off
        off.target = self
        shortcuts.addItem(off)
        let shortcutItem = NSMenuItem(title: "Keyboard Shortcut", action: nil, keyEquivalent: "")
        shortcutItem.submenu = shortcuts
        menu.addItem(shortcutItem)

        let finder = NSMenuItem(title: "Also Minimize Finder Windows", action: #selector(toggleFinderWindows), keyEquivalent: "")
        finder.state = controller.minimizesFinderWindows ? .on : .off
        finder.target = self
        menu.addItem(finder)

        let login = NSMenuItem(title: "Open at Login", action: #selector(toggleOpenAtLogin), keyEquivalent: "")
        login.state = SMAppService.mainApp.status == .enabled ? .on : .off
        login.target = self
        menu.addItem(login)

        menu.addItem(.separator())
        let about = NSMenuItem(title: "About Show Desktop", action: #selector(showAbout), keyEquivalent: "")
        about.target = self
        menu.addItem(about)
        menu.addItem(NSMenuItem(title: "Quit Show Desktop", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    }

    @objc private func toggleFromMenu() { toggle() }

    @objc private func chooseShortcut(_ sender: NSMenuItem) {
        shortcut = sender.representedObject as? KeyShortcut
        registerShortcut()
    }

    @objc private func recordShortcut() {
        // Frees the current shortcut, so pressing it records it instead of showing the Desktop.
        hotKey.unregister()
        recorder.show()
    }

    @objc private func toggleFinderWindows() {
        controller.minimizesFinderWindows.toggle()
        defaults.set(controller.minimizesFinderWindows, forKey: Key.minimizesFinderWindows)
    }

    @objc private func toggleOpenAtLogin() {
        if SMAppService.mainApp.status == .enabled {
            try? SMAppService.mainApp.unregister()
        } else {
            try? SMAppService.mainApp.register()
        }
    }

    @objc private func showAbout() {
        NSApp.activate()
        NSApp.orderFrontStandardAboutPanel(options: [
            .credits: NSAttributedString(
                string: "Free and open source. No internet access.\ngithub.com/stanczykwyatt/show-desktop",
                attributes: [.font: NSFont.systemFont(ofSize: 11), .foregroundColor: NSColor.secondaryLabelColor]
            ),
        ])
    }
}
