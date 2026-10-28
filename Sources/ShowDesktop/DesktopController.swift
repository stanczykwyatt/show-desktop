import AppKit
import ShowDesktopCore

/// Hides every app so the Desktop is clear, and puts everything back exactly as it was on the next press.
///
/// Apps are hidden with the same call as ⌘H, so nothing is closed, quit or moved, and nothing is
/// lost if Show Desktop itself quits: you can always bring an app back from the Dock.
@MainActor
final class DesktopController {
    private var session = DesktopSession()
    var minimizesFinderWindows = true

    var isShowingDesktop: Bool { session.isShowingDesktop }

    func toggle() {
        session.isShowingDesktop ? restore() : showDesktop()
    }

    private func showDesktop() {
        let me = ProcessInfo.processInfo.processIdentifier
        let visible = NSWorkspace.shared.runningApplications.filter {
            $0.activationPolicy == .regular && !$0.isHidden && $0.processIdentifier != me && $0.bundleIdentifier != FinderWindows.bundleID
        }
        let order = StackingOrder.backToFront(visible.map(\.processIdentifier), windows: Self.onScreenWindows())
        session.begin(hiding: order)

        // Finder goes in front first, since it owns the Desktop. Hiding the front app any other way just
        // makes macOS bring the next app forward. activate() rather than opening Finder, which would
        // open a new window when none are open.
        hide(visible, attemptsLeft: 3)

        if minimizesFinderWindows {
            FinderWindows.minimizeAll { ids in
                Task { @MainActor in self.session.recordMinimizedFinderWindows(ids) }
            }
        }
    }

    /// Puts Finder in front and hides the apps, then checks again: an app that was busy launching or
    /// switching can miss the first request, and macOS may bring it forward again.
    private func hide(_ apps: [NSRunningApplication], attemptsLeft: Int) {
        NSRunningApplication.runningApplications(withBundleIdentifier: FinderWindows.bundleID).first?.activate()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            guard self.session.isShowingDesktop else { return }
            apps.forEach { $0.hide() }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                let stillVisible = apps.filter { !$0.isHidden && !$0.isTerminated }
                guard self.session.isShowingDesktop, !stillVisible.isEmpty, attemptsLeft > 1 else { return }
                self.hide(stillVisible, attemptsLeft: attemptsLeft - 1)
            }
        }
    }

    private func restore() {
        let running = Set(NSWorkspace.shared.runningApplications.map(\.processIdentifier))
        let plan = session.end(stillRunning: running)
        FinderWindows.restore(plan.finderWindows)

        let apps = plan.apps.compactMap { NSRunningApplication(processIdentifier: $0) }
        // Unhiding keeps each app's windows exactly where they were.
        apps.forEach { $0.unhide() }
        if let front = plan.front.flatMap({ NSRunningApplication(processIdentifier: $0) }) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { front.activate() }
        }
    }

    /// Which app owns each normal window on screen, front to back. Without Screen Recording permission
    /// macOS leaves out window titles and contents, and Show Desktop never asks for it.
    private static func onScreenWindows() -> [WindowEntry] {
        let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] ?? []
        return list.compactMap { window in
            guard let pid = window[kCGWindowOwnerPID as String] as? Int32,
                  let layer = window[kCGWindowLayer as String] as? Int else { return nil }
            return WindowEntry(ownerPID: pid, layer: layer)
        }
    }
}
