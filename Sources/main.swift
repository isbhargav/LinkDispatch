import AppKit

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate

// We're an agent app (menu bar only, no dock icon)
// This is set via Info.plist LSUIElement, but enforce it here too
app.setActivationPolicy(.accessory)

app.run()
