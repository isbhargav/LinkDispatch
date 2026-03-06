import AppKit

// MARK: - Hover-aware browser button

final class BrowserButtonView: NSView {
    var onClick: (() -> Void)?
    private let iconView = NSImageView()
    private let label = NSTextField(labelWithString: "")
    private let hoverLayer = CALayer()
    private var isHovered = false

    init(browser: BrowserInfo, index: Int) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        wantsLayer = true

        // Hover background
        hoverLayer.cornerRadius = 10
        hoverLayer.backgroundColor = NSColor.white.withAlphaComponent(0.0).cgColor
        layer?.addSublayer(hoverLayer)

        // Icon
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.imageScaling = .scaleProportionallyUpOrDown
        if let icon = browser.icon {
            iconView.image = icon
        }

        // Label
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 11, weight: .medium)
        label.textColor = .labelColor
        label.alignment = .center
        label.lineBreakMode = .byTruncatingTail
        label.maximumNumberOfLines = 1

        label.stringValue = browser.name

        // Shortcut badge (1-9)
        let badge = NSTextField(labelWithString: "")
        badge.translatesAutoresizingMaskIntoConstraints = false
        badge.font = .monospacedSystemFont(ofSize: 9, weight: .medium)
        badge.textColor = .tertiaryLabelColor
        badge.alignment = .center
        if index < 9 {
            badge.stringValue = "\(index + 1)"
        }

        addSubview(iconView)
        addSubview(label)
        addSubview(badge)

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 76),
            heightAnchor.constraint(equalToConstant: 96),

            iconView.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            iconView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 48),
            iconView.heightAnchor.constraint(equalToConstant: 48),

            label.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 6),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -2),

            badge.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 1),
            badge.centerXAnchor.constraint(equalTo: centerXAnchor),
        ])

        // Tracking area for hover
        let trackingArea = NSTrackingArea(
            rect: .zero,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self
        )
        addTrackingArea(trackingArea)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layout() {
        super.layout()
        hoverLayer.frame = bounds.insetBy(dx: 2, dy: 2)
    }

    override func mouseEntered(with event: NSEvent) {
        isHovered = true
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.15
            hoverLayer.backgroundColor = NSColor.white.withAlphaComponent(0.1).cgColor
        }
    }

    override func mouseExited(with event: NSEvent) {
        isHovered = false
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.15
            hoverLayer.backgroundColor = NSColor.white.withAlphaComponent(0.0).cgColor
        }
    }

    override func mouseDown(with event: NSEvent) {
        hoverLayer.backgroundColor = NSColor.white.withAlphaComponent(0.2).cgColor
    }

    override func mouseUp(with event: NSEvent) {
        hoverLayer.backgroundColor = NSColor.white.withAlphaComponent(0.0).cgColor
        if bounds.contains(convert(event.locationInWindow, from: nil)) {
            onClick?()
        }
    }
}

// MARK: - Modern picker window

final class BrowserPickerWindow: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    private var url: URL?
    private let stackView = NSStackView()
    private let urlLabel = NSTextField(labelWithString: "")
    private let cancelButton = NSButton()

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 160),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        self.level = .floating
        self.isMovableByWindowBackground = true
        self.hidesOnDeactivate = false
        self.animationBehavior = .utilityWindow
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true

        setupUI()
    }

    private func setupUI() {
        // Vibrancy blur background
        let visualEffect = NSVisualEffectView()
        visualEffect.state = .active
        visualEffect.material = .hudWindow
        visualEffect.blendingMode = .behindWindow
        visualEffect.wantsLayer = true
        visualEffect.layer?.cornerRadius = 16
        visualEffect.layer?.masksToBounds = true
        visualEffect.translatesAutoresizingMaskIntoConstraints = false

        let container = NSView()
        container.wantsLayer = true
        contentView = container
        container.addSubview(visualEffect)

        // Title
        let titleLabel = NSTextField(labelWithString: "Open with")
        titleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        titleLabel.textColor = .labelColor
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        // Cancel button
        cancelButton.title = "Cancel  esc"
        cancelButton.bezelStyle = .accessoryBarAction
        cancelButton.isBordered = false
        cancelButton.font = .systemFont(ofSize: 12)
        cancelButton.contentTintColor = .secondaryLabelColor
        cancelButton.target = self
        cancelButton.action = #selector(cancelClicked)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false

        // URL display
        urlLabel.font = .systemFont(ofSize: 11)
        urlLabel.textColor = .secondaryLabelColor
        urlLabel.lineBreakMode = .byTruncatingMiddle
        urlLabel.maximumNumberOfLines = 1
        urlLabel.translatesAutoresizingMaskIntoConstraints = false

        // Separator
        let separator = NSBox()
        separator.boxType = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false

        // Browser grid
        stackView.orientation = .horizontal
        stackView.spacing = 4
        stackView.alignment = .top
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false

        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
        scrollView.drawsBackground = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = stackView

        visualEffect.addSubview(titleLabel)
        visualEffect.addSubview(cancelButton)
        visualEffect.addSubview(urlLabel)
        visualEffect.addSubview(separator)
        visualEffect.addSubview(scrollView)

        NSLayoutConstraint.activate([
            visualEffect.topAnchor.constraint(equalTo: container.topAnchor),
            visualEffect.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            visualEffect.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            visualEffect.bottomAnchor.constraint(equalTo: container.bottomAnchor),

            titleLabel.topAnchor.constraint(equalTo: visualEffect.topAnchor, constant: 14),
            titleLabel.leadingAnchor.constraint(equalTo: visualEffect.leadingAnchor, constant: 18),

            cancelButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            cancelButton.trailingAnchor.constraint(equalTo: visualEffect.trailingAnchor, constant: -14),

            urlLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            urlLabel.leadingAnchor.constraint(equalTo: visualEffect.leadingAnchor, constant: 18),
            urlLabel.trailingAnchor.constraint(equalTo: visualEffect.trailingAnchor, constant: -18),

            separator.topAnchor.constraint(equalTo: urlLabel.bottomAnchor, constant: 10),
            separator.leadingAnchor.constraint(equalTo: visualEffect.leadingAnchor, constant: 14),
            separator.trailingAnchor.constraint(equalTo: visualEffect.trailingAnchor, constant: -14),

            scrollView.topAnchor.constraint(equalTo: separator.bottomAnchor, constant: 4),
            scrollView.leadingAnchor.constraint(equalTo: visualEffect.leadingAnchor, constant: 10),
            scrollView.trailingAnchor.constraint(equalTo: visualEffect.trailingAnchor, constant: -10),
            scrollView.bottomAnchor.constraint(equalTo: visualEffect.bottomAnchor, constant: -8),
            scrollView.heightAnchor.constraint(equalToConstant: 100),

            stackView.topAnchor.constraint(equalTo: scrollView.contentView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.contentView.leadingAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentView.bottomAnchor),
        ])
    }

    func show(for url: URL) {
        self.url = url
        urlLabel.stringValue = url.absoluteString

        // Rebuild browser buttons
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let browsers = BrowserManager.shared.browsers
        for (index, browser) in browsers.enumerated() {
            let buttonView = BrowserButtonView(browser: browser, index: index)
            buttonView.onClick = { [weak self] in
                guard let self = self else { return }
                BrowserManager.shared.open(url: url, with: browser)
                self.animateOut()
            }
            stackView.addArrangedSubview(buttonView)
        }

        // Size window to fit browsers
        let width = max(360, CGFloat(browsers.count) * 80 + 20)
        let windowSize = NSSize(width: min(width, 640), height: 160)
        setContentSize(windowSize)

        // Position centered on screen, upper third
        let screenFrame = NSScreen.main?.visibleFrame ?? .zero
        let origin = NSPoint(
            x: screenFrame.midX - windowSize.width / 2,
            y: screenFrame.midY + screenFrame.height * 0.1
        )
        setFrameOrigin(origin)

        // Animate in
        alphaValue = 0
        makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.18
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            self.animator().alphaValue = 1
        }
    }

    private func animateOut() {
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.12
            ctx.timingFunction = CAMediaTimingFunction(name: .easeIn)
            self.animator().alphaValue = 0
        }, completionHandler: {
            self.orderOut(nil)
            self.alphaValue = 1
        })
    }

    @objc private func cancelClicked() {
        animateOut()
    }

    override func cancelOperation(_ sender: Any?) {
        animateOut()
    }

    // Handle keyboard shortcuts: number keys 1-9 to pick browser, Esc to close
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Escape
            animateOut()
            return
        }

        let chars = event.charactersIgnoringModifiers ?? ""
        if let digit = chars.first?.wholeNumberValue, digit >= 1, digit <= 9 {
            let index = digit - 1
            let browsers = BrowserManager.shared.browsers
            guard index < browsers.count, let url = url else { return }
            BrowserManager.shared.open(url: url, with: browsers[index])
            animateOut()
            return
        }

        super.keyDown(with: event)
    }

}
