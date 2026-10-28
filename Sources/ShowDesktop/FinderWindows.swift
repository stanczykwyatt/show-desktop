import AppKit
import CoreServices

/// Minimizes open Finder windows and brings them back, through Apple Events.
///
/// This is optional: the app's entitlements allow events to Finder and nothing else, and macOS
/// asks you before the first one is sent. The scripts only change whether windows are minimized.
enum FinderWindows {
    static let bundleID = "com.apple.finder"

    /// NSAppleScript can't run two scripts at once, so every script runs on this queue.
    private static let queue = DispatchQueue(label: "com.stanczykwyatt.ShowDesktop.finder", qos: .userInitiated)

    /// Minimizes every open Finder window and returns their IDs, so exactly those can come back.
    static func minimizeAll(completion: @escaping @Sendable ([Int]) -> Void) {
        run("""
            tell application id "com.apple.finder"
                set ids to {}
                repeat with w in (every Finder window whose collapsed is false)
                    set end of ids to id of w
                    set collapsed of w to true
                end repeat
                return ids
            end tell
            """) { result in
            guard let result else { return completion([]) }
            completion((0..<result.numberOfItems).compactMap { result.atIndex($0 + 1).map { Int($0.int32Value) } })
        }
    }

    /// Un-minimizes the windows with these IDs. Windows closed in the meantime are skipped.
    static func restore(_ ids: [Int]) {
        guard !ids.isEmpty else { return }
        // Only integers go into the script, so nothing from a window can change what it does.
        let lines = ids.map { "try\nset collapsed of Finder window id \($0) to false\nend try" }
        run("tell application id \"com.apple.finder\"\n\(lines.joined(separator: "\n"))\nend tell") { _ in }
    }

    /// Whether you've allowed this app to control Finder. Asks the first time if `ask` is true.
    static func isAllowed(ask: Bool) -> Bool {
        var target = AEAddressDesc()
        let id = bundleID.data(using: .utf8)!
        let created = id.withUnsafeBytes { bytes in
            AECreateDesc(DescType(typeApplicationBundleID), bytes.baseAddress, bytes.count, &target)
        }
        guard created == noErr else { return false }
        defer { AEDisposeDesc(&target) }
        let status = AEDeterminePermissionToAutomateTarget(&target, AEEventClass(typeWildCard), AEEventID(typeWildCard), ask)
        return status == noErr
    }

    private static func run(_ source: String, completion: @escaping @Sendable (NSAppleEventDescriptor?) -> Void) {
        queue.async {
            guard isAllowed(ask: true) else { return completion(nil) }
            var error: NSDictionary?
            let result = NSAppleScript(source: source)?.executeAndReturnError(&error)
            completion(error == nil ? result : nil)
        }
    }
}
