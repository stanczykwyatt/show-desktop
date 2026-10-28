import AppKit

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
// A menu bar app: no Dock icon and no main window.
app.setActivationPolicy(.accessory)
app.run()
