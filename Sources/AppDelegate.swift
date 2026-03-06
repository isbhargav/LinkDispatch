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
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "link", accessibilityDescription: "LinkDispatch")
                ?? makeTextIcon()
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

    private func makeTextIcon() -> NSImage {
        let img = NSImage(size: NSSize(width: 18, height: 18))
        img.lockFocus()
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12, weight: .bold),
            .foregroundColor: NSColor.labelColor
        ]
        "LD".draw(at: NSPoint(x: 0, y: 2), withAttributes: attrs)
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
