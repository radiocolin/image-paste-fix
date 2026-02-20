import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem!
    private var enabledMenuItem: NSMenuItem!
    private var loginMenuItem: NSMenuItem!
    private let monitor = PasteboardMonitor()
    private let loginItemManager = LoginItemManager()

    private var isEnabled: Bool {
        get { UserDefaults.standard.object(forKey: "Enabled") as? Bool ?? true }
        set {
            UserDefaults.standard.set(newValue, forKey: "Enabled")
            enabledMenuItem.state = newValue ? .on : .off
            if newValue { monitor.start() } else { monitor.stop() }
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
            button.image = NSImage(
                systemSymbolName: "doc.on.clipboard",
                accessibilityDescription: "ImagePasteFix"
            )?.withSymbolConfiguration(config)
        }

        let menu = NSMenu()

        enabledMenuItem = NSMenuItem(title: "Enabled", action: #selector(toggleEnabled), keyEquivalent: "")
        enabledMenuItem.target = self
        enabledMenuItem.state = isEnabled ? .on : .off
        menu.addItem(enabledMenuItem)

        loginMenuItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        loginMenuItem.target = self
        loginMenuItem.state = loginItemManager.isEnabled ? .on : .off
        menu.addItem(loginMenuItem)

        menu.addItem(.separator())

        let aboutItem = NSMenuItem(title: "About Image Paste Fixer", action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu

        if isEnabled {
            monitor.start()
        }
    }

    @objc private func toggleEnabled() {
        isEnabled = !isEnabled
    }

    @objc private func toggleLaunchAtLogin() {
        let newValue = !loginItemManager.isEnabled
        loginItemManager.isEnabled = newValue
        loginMenuItem.state = newValue ? .on : .off
    }

    @objc private func showAbout() {
        let font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        let style = NSMutableParagraphStyle()
        style.alignment = .center

        let base: [NSAttributedString.Key: Any] = [
            .font: font,
            .paragraphStyle: style,
        ]

        let credits = NSMutableAttributedString(string: "© 2026 Colin Weir\n", attributes: base)
        var linkAttrs = base
        linkAttrs[.link] = URL(string: "https://colinsent.me")!
        credits.append(NSAttributedString(string: "colinsent.me", attributes: linkAttrs))

        NSApp.orderFrontStandardAboutPanel(options: [
            .applicationName: "Image Paste Fixer",
            .credits: credits,
        ])
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
