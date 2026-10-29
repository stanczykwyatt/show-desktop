import AppKit
import Carbon.HIToolbox
import Observation
import ShowDesktopCore
import SwiftUI

/// A small window that records a new keyboard shortcut.
///
/// It only listens to key presses in its own window, through a local event monitor, so it
/// needs no Accessibility or Input Monitoring permission and never sees typing in other apps.
@MainActor
final class ShortcutRecorder: NSObject, NSWindowDelegate {
    /// Asked to use a recorded shortcut. Returns false if another app already has it.
    var onRecord: (KeyShortcut) -> Bool = { _ in false }
    /// Called when the window closes, whether or not a shortcut was recorded.
    var onClose: () -> Void = {}

    private let model = RecorderModel()
    private var window: NSWindow?
    private var monitor: Any?

    var isShown: Bool { window != nil }

    func show() {
        if let window {
            NSApp.activate()
            window.makeKeyAndOrderFront(nil)
            return
        }
        model.reset()
        let controller = NSHostingController(rootView: RecorderView(
            model: model,
            useDefault: { [weak self] in self?.use(.standard) },
            cancel: { [weak self] in self?.close() }
        ))
        controller.sizingOptions = .preferredContentSize
        let window = NSWindow(contentViewController: controller)
        window.title = "Keyboard Shortcut"
        window.styleMask = [.titled, .closable]
        window.level = .floating
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.center()
        self.window = window

        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [weak self] event in
            let used = MainActor.assumeIsolated { self?.handle(event) ?? false }
            return used ? nil : event
        }
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
    }

    func close() {
        window?.close()
    }

    func windowWillClose(_ notification: Notification) {
        if let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
        window?.delegate = nil
        window = nil
        onClose()
    }

    /// Returns whether the event was used. Every shortcut-like key press is, so typing a
    /// shortcut can't also press a button or close the window.
    private func handle(_ event: NSEvent) -> Bool {
        guard let window, event.window === window else { return false }
        if event.type == .flagsChanged {
            model.heldModifiers = KeyShortcut.carbonModifiers(event.modifierFlags)
            return false
        }
        // Tab, Shift-Tab and Space on their own can't be shortcuts, so they still move between
        // and press the buttons for people who get around with the keyboard.
        let modifiers = KeyShortcut.carbonModifiers(event.modifierFlags)
        if (event.keyCode == UInt16(kVK_Tab) && modifiers & ~Modifier.shift == 0)
            || (event.keyCode == UInt16(kVK_Space) && modifiers == 0) {
            return false
        }
        guard !event.isARepeat else { return true }
        switch KeyShortcut.recorded(from: event) {
        case .cancel:
            close()
        case .refuse(let problem):
            let pressed = KeyShortcut(
                keyCode: UInt32(event.keyCode),
                modifiers: KeyShortcut.carbonModifiers(event.modifierFlags),
                key: KeyShortcut.label(for: event) ?? "?"
            )
            model.message = .refused(problem, keys: pressed.displayString)
            NSSound.beep()
        case .use(let shortcut):
            use(shortcut)
        }
        return true
    }

    private func use(_ shortcut: KeyShortcut) {
        if onRecord(shortcut) {
            close()
        } else {
            model.message = .taken(keys: shortcut.displayString)
            NSSound.beep()
        }
    }
}

@MainActor
@Observable
final class RecorderModel {
    enum Message: Equatable {
        case prompt
        case refused(ShortcutProblem, keys: String)
        case taken(keys: String)
    }

    var message = Message.prompt
    /// The modifier keys being held down right now, shown while you type.
    var heldModifiers: UInt32 = 0

    func reset() {
        message = .prompt
        heldModifiers = 0
    }
}

struct RecorderView: View {
    let model: RecorderModel
    let useDefault: () -> Void
    let cancel: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Text("Press the keys you want to use to show the Desktop.")
                .font(.headline)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Text(preview)
                .font(.system(size: 26, weight: .medium, design: .rounded))
                .foregroundStyle(model.heldModifiers == 0 ? .secondary : .primary)
                .frame(maxWidth: .infinity, minHeight: 60)
                .background(.quaternary.opacity(0.6), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.accentColor.opacity(0.8), lineWidth: 2)
                )
                .accessibilityLabel(model.heldModifiers == 0 ? "Waiting for a shortcut" : "Holding \(preview)")

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                if isProblem {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .accessibilityHidden(true)
                }
                Text(hint)
                    .foregroundStyle(isProblem ? .primary : .secondary)
                    .multilineTextAlignment(isProblem ? .leading : .center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .font(.callout)
            .frame(minHeight: 36, alignment: .top)

            HStack {
                Button("Use \(KeyShortcut.standard.displayString)", action: useDefault)
                Spacer()
                Button("Cancel", action: cancel)
            }
        }
        .padding(20)
        .frame(width: 360)
    }

    private var preview: String {
        guard model.heldModifiers != 0 else { return "Type a shortcut" }
        return KeyShortcut(keyCode: 0, modifiers: model.heldModifiers, key: "").displayString + "…"
    }

    private var isProblem: Bool {
        model.message != .prompt
    }

    private var hint: String {
        switch model.message {
        case .prompt:
            "Use ⌃, or ⌘ with ⇧ or ⌥, plus a key. Function keys work on their own. Press Esc to cancel."
        case .refused(.needsModifier, let keys):
            "\(keys) would get in the way of typing. Add ⌃, or ⌘ with ⇧ or ⌥."
        case .refused(.alreadyUsed, let keys):
            "\(keys) is already used by macOS or most apps. Try another one."
        case .taken(let keys):
            "Another app is already using \(keys). Try another one."
        }
    }
}
