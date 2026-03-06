import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var pickerWindow: BrowserPickerWindow!
    private var settingsController: SettingsWindowController?

    func applicationWillFinishLaunching(_ notification: Notification) {
        // Register for URL open events EARLY — before the system delivers them
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleGetURL(_:withReplyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Detect installed browsers
        BrowserManager.shared.refresh()

        // Create the picker window (reused for each URL)
        pickerWindow = BrowserPickerWindow()

        // Setup status bar icon
        setupStatusBar()
    }

    // Modern delegate method for receiving URLs (backup for Apple Events)
    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            handleURL(url)
        }
    }

    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: 30)

        if let button = statusItem.button {
            button.image = makeMenuBarIcon()
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "About LinkDispatch", action: #selector(showAbout), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(showSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "Refresh Browsers", action: #selector(refreshBrowsers), keyEquivalent: "r"))
        menu.addItem(NSMenuItem.separator())

        let browsersSubmenu = NSMenu()
        let browsersItem = NSMenuItem(title: "Installed Browsers", action: nil, keyEquivalent: "")
        browsersItem.submenu = browsersSubmenu
        for browser in BrowserManager.shared.browsers {
            let item = NSMenuItem(title: browser.name, action: nil, keyEquivalent: "")
            if let icon = browser.icon {
                let small = NSImage(size: NSSize(width: 16, height: 16))
                small.lockFocus()
                icon.draw(in: NSRect(x: 0, y: 0, width: 16, height: 16))
                small.unlockFocus()
                item.image = small
            }
            browsersSubmenu.addItem(item)
        }
        menu.addItem(browsersItem)

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit LinkDispatch", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem.menu = menu
    }

    private func makeMenuBarIcon() -> NSImage {
        let s: CGFloat = 28
        let img = NSImage(size: NSSize(width: s, height: s))
        img.lockFocus()

        guard let ctx = NSGraphicsContext.current?.cgContext else {
            img.unlockFocus()
            return img
        }

        let lineWidth: CGFloat = 1.8
        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)
        ctx.setLineWidth(lineWidth)
        ctx.setStrokeColor(NSColor.black.cgColor)

        // Chain links (two interlocking rounded rects, tilted -30°)
        let cx = s * 0.38
        let cy = s * 0.52
        let linkW = s * 0.28
        let linkH = s * 0.15
        let linkR = linkH / 2

        // Left link
        ctx.saveGState()
        ctx.translateBy(x: cx, y: cy)
        ctx.rotate(by: -CGFloat.pi / 6)
        let leftLink = CGRect(x: -linkW / 2, y: -linkH / 2, width: linkW, height: linkH)
        ctx.addPath(CGPath(roundedRect: leftLink, cornerWidth: linkR, cornerHeight: linkR, transform: nil))
        ctx.strokePath()
        ctx.restoreGState()

        // Right link
        let ox = s * 0.14
        let oy = -s * 0.08
        ctx.saveGState()
        ctx.translateBy(x: cx + ox, y: cy + oy)
        ctx.rotate(by: -CGFloat.pi / 6)
        let rightLink = CGRect(x: -linkW / 2, y: -linkH / 2, width: linkW, height: linkH)
        ctx.addPath(CGPath(roundedRect: rightLink, cornerWidth: linkR, cornerHeight: linkR, transform: nil))
        ctx.strokePath()
        ctx.restoreGState()

        // Three dispatch arrows fanning out to the right
        let arrowStart = CGPoint(x: s * 0.58, y: s * 0.44)
        let arrowLen = s * 0.22
        let headLen: CGFloat = 4.0
        let arrowLineWidth: CGFloat = 1.6

        let angles: [CGFloat] = [-0.50, 0.0, 0.50]
        ctx.setLineWidth(arrowLineWidth)
        ctx.setStrokeColor(NSColor.black.cgColor)

        for angle in angles {
            let endX = arrowStart.x + arrowLen * cos(angle)
            let endY = arrowStart.y + arrowLen * sin(angle)

            // Shaft
            ctx.move(to: arrowStart)
            ctx.addLine(to: CGPoint(x: endX, y: endY))
            ctx.strokePath()

            // Arrowhead
            let headAngle1 = angle + CGFloat.pi * 0.8
            let headAngle2 = angle - CGFloat.pi * 0.8
            ctx.move(to: CGPoint(x: endX + headLen * cos(headAngle1), y: endY + headLen * sin(headAngle1)))
            ctx.addLine(to: CGPoint(x: endX, y: endY))
            ctx.addLine(to: CGPoint(x: endX + headLen * cos(headAngle2), y: endY + headLen * sin(headAngle2)))
            ctx.strokePath()
        }

        img.unlockFocus()
        img.isTemplate = true
        return img
    }

    @objc private func handleGetURL(_ event: NSAppleEventDescriptor, withReplyEvent reply: NSAppleEventDescriptor) {
        guard let urlString = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue,
              let url = URL(string: urlString) else { return }
        handleURL(url)
    }

    private func handleURL(_ url: URL) {
        // Ensure browsers are loaded and picker exists
        if pickerWindow == nil {
            BrowserManager.shared.refresh()
            pickerWindow = BrowserPickerWindow()
        }

        // Refresh browsers in case new ones were installed
        BrowserManager.shared.refresh()

        // Check rules
        if let bundleID = RuleEngine.shared.resolve(url: url) {
            BrowserManager.shared.open(url: url, withBundleID: bundleID)
            return
        }

        // Show picker
        pickerWindow.show(for: url)
    }

    @objc private func showSettings() {
        if settingsController == nil {
            settingsController = SettingsWindowController()
        }
        settingsController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func showAbout() {
        let alert = NSAlert()
        alert.messageText = "LinkDispatch"
        alert.informativeText = "A browser chooser for macOS.\n\nSet LinkDispatch as your default browser, then choose which browser to open each link with.\n\nVersion 1.0"
        alert.runModal()
    }

    @objc private func refreshBrowsers() {
        BrowserManager.shared.refresh()
        // Rebuild menu
        setupStatusBar()
    }
}
