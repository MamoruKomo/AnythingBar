import AppKit

@MainActor
final class MenuBarController: NSObject {
    private let statusItem: NSStatusItem
    private let openActionBar: () -> Void
    private let openSettings: () -> Void
    private let openHistory: () -> Void

    init(
        openActionBar: @escaping () -> Void,
        openSettings: @escaping () -> Void,
        openHistory: @escaping () -> Void
    ) {
        self.openActionBar = openActionBar
        self.openSettings = openSettings
        self.openHistory = openHistory
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()
        configureStatusItem()
    }

    private func configureStatusItem() {
        statusItem.button?.image = NSImage(
            systemSymbolName: "command.square",
            accessibilityDescription: "AnythingBar"
        )
        statusItem.button?.toolTip = "AnythingBar"

        let menu = NSMenu()
        menu.addItem(menuItem("AnythingBarを開く", action: #selector(openActionBarSelected)))
        menu.addItem(.separator())
        menu.addItem(menuItem("設定…", action: #selector(openSettingsSelected)))
        menu.addItem(menuItem("履歴…", action: #selector(openHistorySelected)))
        menu.addItem(.separator())

        let accessibilityItem = NSMenuItem(
            title: "Accessibility対応は今後追加予定",
            action: nil,
            keyEquivalent: ""
        )
        accessibilityItem.isEnabled = false
        menu.addItem(accessibilityItem)

        menu.addItem(.separator())
        menu.addItem(menuItem("AnythingBarを終了", action: #selector(quitSelected)))
        statusItem.menu = menu
    }

    private func menuItem(_ title: String, action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        return item
    }

    @objc private func openActionBarSelected() {
        openActionBar()
    }

    @objc private func openSettingsSelected() {
        openSettings()
    }

    @objc private func openHistorySelected() {
        openHistory()
    }

    @objc private func quitSelected() {
        NSApplication.shared.terminate(nil)
    }
}
