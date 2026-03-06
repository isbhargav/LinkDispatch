import AppKit

final class SettingsWindowController: NSWindowController, NSTableViewDataSource, NSTableViewDelegate {
    private var rules: [Rule] = []
    private let tableView = NSTableView()
    private var defaultBrowserPopup: NSPopUpButton!
    private var promptAlwaysCheckbox: NSButton!

    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 440),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "LinkDispatch Settings"
        window.center()
        window.minSize = NSSize(width: 420, height: 340)

        super.init(window: window)
        setupUI()
        loadData()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        guard let contentView = window?.contentView else { return }

        let tabView = NSTabView()
        tabView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(tabView)

        NSLayoutConstraint.activate([
            tabView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            tabView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            tabView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            tabView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
        ])

        // General tab
        let generalTab = NSTabViewItem(identifier: "general")
        generalTab.label = "General"
        generalTab.view = createGeneralTab()
        tabView.addTabViewItem(generalTab)

        // Rules tab
        let rulesTab = NSTabViewItem(identifier: "rules")
        rulesTab.label = "Rules"
        rulesTab.view = createRulesTab()
        tabView.addTabViewItem(rulesTab)
    }

    private func createGeneralTab() -> NSView {
        let view = NSView()

        // Default browser
        let defaultLabel = NSTextField(labelWithString: "Default browser:")
        defaultLabel.translatesAutoresizingMaskIntoConstraints = false

        defaultBrowserPopup = NSPopUpButton()
        defaultBrowserPopup.translatesAutoresizingMaskIntoConstraints = false
        defaultBrowserPopup.target = self
        defaultBrowserPopup.action = #selector(defaultBrowserChanged(_:))

        // Prompt always checkbox
        promptAlwaysCheckbox = NSButton(checkboxWithTitle: "Always show browser picker (ignore rules and default)", target: self, action: #selector(promptAlwaysChanged(_:)))
        promptAlwaysCheckbox.translatesAutoresizingMaskIntoConstraints = false

        // Set as default browser button
        let setDefaultButton = NSButton(title: "Set LinkDispatch as Default Browser", target: self, action: #selector(setAsDefaultBrowser(_:)))
        setDefaultButton.translatesAutoresizingMaskIntoConstraints = false
        setDefaultButton.bezelStyle = .rounded

        let helpText = NSTextField(wrappingLabelWithString: "When set as the default browser, LinkDispatch intercepts all link clicks and lets you choose which browser to use.")
        helpText.font = .systemFont(ofSize: 11)
        helpText.textColor = .secondaryLabelColor
        helpText.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(defaultLabel)
        view.addSubview(defaultBrowserPopup)
        view.addSubview(promptAlwaysCheckbox)
        view.addSubview(setDefaultButton)
        view.addSubview(helpText)

        NSLayoutConstraint.activate([
            defaultLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            defaultLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            defaultBrowserPopup.centerYAnchor.constraint(equalTo: defaultLabel.centerYAnchor),
            defaultBrowserPopup.leadingAnchor.constraint(equalTo: defaultLabel.trailingAnchor, constant: 8),
            defaultBrowserPopup.widthAnchor.constraint(greaterThanOrEqualToConstant: 200),

            promptAlwaysCheckbox.topAnchor.constraint(equalTo: defaultLabel.bottomAnchor, constant: 16),
            promptAlwaysCheckbox.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            setDefaultButton.topAnchor.constraint(equalTo: promptAlwaysCheckbox.bottomAnchor, constant: 24),
            setDefaultButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            helpText.topAnchor.constraint(equalTo: setDefaultButton.bottomAnchor, constant: 12),
            helpText.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            helpText.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
        ])

        return view
    }

    private func createRulesTab() -> NSView {
        let view = NSView()

        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        let patternCol = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("pattern"))
        patternCol.title = "URL Pattern"
        patternCol.width = 200
        patternCol.minWidth = 100

        let browserCol = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("browser"))
        browserCol.title = "Browser"
        browserCol.width = 160
        browserCol.minWidth = 100

        let enabledCol = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("enabled"))
        enabledCol.title = "On"
        enabledCol.width = 30
        enabledCol.minWidth = 30

        tableView.addTableColumn(enabledCol)
        tableView.addTableColumn(patternCol)
        tableView.addTableColumn(browserCol)
        tableView.dataSource = self
        tableView.delegate = self

        scrollView.documentView = tableView

        let addButton = NSButton(title: "+", target: self, action: #selector(addRule(_:)))
        addButton.bezelStyle = .smallSquare
        addButton.translatesAutoresizingMaskIntoConstraints = false

        let removeButton = NSButton(title: "-", target: self, action: #selector(removeRule(_:)))
        removeButton.bezelStyle = .smallSquare
        removeButton.translatesAutoresizingMaskIntoConstraints = false

        let helpLabel = NSTextField(labelWithString: "Patterns: \"github.com\", \"*.google.com\", \"slack\"")
        helpLabel.font = .systemFont(ofSize: 11)
        helpLabel.textColor = .secondaryLabelColor
        helpLabel.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(scrollView)
        view.addSubview(addButton)
        view.addSubview(removeButton)
        view.addSubview(helpLabel)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: 12),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            scrollView.bottomAnchor.constraint(equalTo: addButton.topAnchor, constant: -8),

            addButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            addButton.bottomAnchor.constraint(equalTo: helpLabel.topAnchor, constant: -8),
            addButton.widthAnchor.constraint(equalToConstant: 24),

            removeButton.leadingAnchor.constraint(equalTo: addButton.trailingAnchor, constant: 2),
            removeButton.centerYAnchor.constraint(equalTo: addButton.centerYAnchor),
            removeButton.widthAnchor.constraint(equalToConstant: 24),

            helpLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            helpLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -12),
        ])

        return view
    }

    private func loadData() {
        rules = RuleEngine.shared.rules

        // Populate default browser popup
        defaultBrowserPopup.removeAllItems()
        defaultBrowserPopup.addItem(withTitle: "Always ask (show picker)")
        for browser in BrowserManager.shared.browsers {
            defaultBrowserPopup.addItem(withTitle: browser.name)
        }

        if let defaultID = RuleEngine.shared.defaultBrowserBundleID,
           let idx = BrowserManager.shared.browsers.firstIndex(where: { $0.bundleIdentifier == defaultID }) {
            defaultBrowserPopup.selectItem(at: idx + 1) // +1 for "Always ask"
        }

        promptAlwaysCheckbox.state = RuleEngine.shared.promptAlways ? .on : .off
        tableView.reloadData()
    }

    @objc private func defaultBrowserChanged(_ sender: NSPopUpButton) {
        let index = sender.indexOfSelectedItem
        if index == 0 {
            RuleEngine.shared.defaultBrowserBundleID = nil
        } else {
            let browsers = BrowserManager.shared.browsers
            if index - 1 < browsers.count {
                RuleEngine.shared.defaultBrowserBundleID = browsers[index - 1].bundleIdentifier
            }
        }
    }

    @objc private func promptAlwaysChanged(_ sender: NSButton) {
        RuleEngine.shared.promptAlways = (sender.state == .on)
    }

    @objc private func setAsDefaultBrowser(_ sender: NSButton) {
        guard let bundleID = Bundle.main.bundleIdentifier else { return }
        // On macOS 12+, open System Settings to default browser
        if let url = URL(string: "x-apple.systempreferences:com.apple.Desktop-Settings.extension") {
            NSWorkspace.shared.open(url)
        }
        // Also try the legacy approach
        LSSetDefaultHandlerForURLScheme("http" as CFString, bundleID as CFString)
        LSSetDefaultHandlerForURLScheme("https" as CFString, bundleID as CFString)

        let alert = NSAlert()
        alert.messageText = "Default Browser"
        alert.informativeText = "If prompted, please confirm LinkDispatch as your default browser in System Settings."
        alert.runModal()
    }

    @objc private func addRule(_ sender: Any) {
        let browsers = BrowserManager.shared.browsers
        let defaultBrowserID = browsers.first?.bundleIdentifier ?? ""
        rules.append(Rule(pattern: "example.com", browserBundleID: defaultBrowserID))
        RuleEngine.shared.rules = rules
        tableView.reloadData()
        tableView.editColumn(1, row: rules.count - 1, with: nil, select: true)
    }

    @objc private func removeRule(_ sender: Any) {
        let row = tableView.selectedRow
        guard row >= 0, row < rules.count else { return }
        rules.remove(at: row)
        RuleEngine.shared.rules = rules
        tableView.reloadData()
    }

    // MARK: - NSTableViewDataSource

    func numberOfRows(in tableView: NSTableView) -> Int {
        return rules.count
    }

    // MARK: - NSTableViewDelegate

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard row < rules.count else { return nil }
        let rule = rules[row]
        let id = tableColumn?.identifier.rawValue ?? ""

        switch id {
        case "enabled":
            let checkbox = NSButton(checkboxWithTitle: "", target: self, action: #selector(toggleRule(_:)))
            checkbox.state = rule.isEnabled ? .on : .off
            checkbox.tag = row
            return checkbox

        case "pattern":
            let field = NSTextField()
            field.stringValue = rule.pattern
            field.isEditable = true
            field.isBordered = false
            field.backgroundColor = .clear
            field.tag = row
            field.target = self
            field.action = #selector(patternEdited(_:))
            return field

        case "browser":
            let popup = NSPopUpButton()
            popup.tag = row
            for browser in BrowserManager.shared.browsers {
                popup.addItem(withTitle: browser.name)
            }
            if let idx = BrowserManager.shared.browsers.firstIndex(where: { $0.bundleIdentifier == rule.browserBundleID }) {
                popup.selectItem(at: idx)
            }
            popup.target = self
            popup.action = #selector(browserForRuleChanged(_:))
            return popup

        default:
            return nil
        }
    }

    @objc private func toggleRule(_ sender: NSButton) {
        guard sender.tag < rules.count else { return }
        rules[sender.tag].isEnabled = (sender.state == .on)
        RuleEngine.shared.rules = rules
    }

    @objc private func patternEdited(_ sender: NSTextField) {
        guard sender.tag < rules.count else { return }
        rules[sender.tag].pattern = sender.stringValue
        RuleEngine.shared.rules = rules
    }

    @objc private func browserForRuleChanged(_ sender: NSPopUpButton) {
        guard sender.tag < rules.count else { return }
        let browsers = BrowserManager.shared.browsers
        let idx = sender.indexOfSelectedItem
        guard idx < browsers.count else { return }
        rules[sender.tag].browserBundleID = browsers[idx].bundleIdentifier
        RuleEngine.shared.rules = rules
    }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat { 26 }
}
