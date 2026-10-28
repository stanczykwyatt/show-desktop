/// A process ID. Kept as a plain integer so this target doesn't need AppKit.
public typealias ProcessID = Int32

/// One on-screen window, as reported by the window server.
public struct WindowEntry: Equatable, Sendable {
    public let ownerPID: ProcessID
    /// 0 for normal app windows. Menus, the Dock and panels sit on higher layers.
    public let layer: Int

    public init(ownerPID: ProcessID, layer: Int) {
        self.ownerPID = ownerPID
        self.layer = layer
    }
}

public enum StackingOrder {
    /// Orders apps back to front by their frontmost normal window.
    ///
    /// `windows` must be front to back, which is how `CGWindowListCopyWindowInfo` returns them.
    /// Apps with no windows on screen go first, so the app that was in front always ends up last.
    public static func backToFront(_ apps: [ProcessID], windows: [WindowEntry]) -> [ProcessID] {
        var depth: [ProcessID: Int] = [:]
        for (index, window) in windows.enumerated() where window.layer == 0 && depth[window.ownerPID] == nil {
            depth[window.ownerPID] = index
        }
        // Stable for apps at the same depth, so the result doesn't depend on hashing.
        return apps.enumerated().sorted { a, b in
            let da = depth[a.element] ?? .max
            let db = depth[b.element] ?? .max
            return da == db ? a.offset < b.offset : da > db
        }.map(\.element)
    }
}

/// Remembers what Show Desktop hid, so the next click puts back exactly that and nothing else.
public struct DesktopSession: Equatable, Sendable {
    public private(set) var isShowingDesktop = false
    /// Apps that were visible before, back to front. The last one is the app you were using.
    public private(set) var hiddenApps: [ProcessID] = []
    /// Finder windows that were open (not minimized) before.
    public private(set) var minimizedFinderWindows: [Int] = []

    public init() {}

    /// Records the apps about to be hidden, already in back-to-front order.
    public mutating func begin(hiding apps: [ProcessID]) {
        hiddenApps = apps
        minimizedFinderWindows = []
        isShowingDesktop = true
    }

    public mutating func recordMinimizedFinderWindows(_ ids: [Int]) {
        guard isShowingDesktop else { return }
        minimizedFinderWindows = ids
    }

    public struct Restore: Equatable, Sendable {
        /// Apps to unhide, back to front. Apps that quit in the meantime are left out.
        public let apps: [ProcessID]
        /// The app to put back in front, if it's still running.
        public let front: ProcessID?
        public let finderWindows: [Int]
    }

    /// Ends the session and says what to put back. Apps that were already hidden before stay hidden,
    /// because they were never recorded.
    public mutating func end(stillRunning: Set<ProcessID>) -> Restore {
        let apps = hiddenApps.filter(stillRunning.contains)
        let restore = Restore(apps: apps, front: apps.last, finderWindows: minimizedFinderWindows)
        self = DesktopSession()
        return restore
    }
}
