import AnythingBarCore
import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController: NSWindowController {
    init(
        settings: SettingsStore,
        hotkeyService: HotkeyService,
        clearHistory: @escaping () -> Result<Void, HistoryStoreError>
    ) {
        let view = SettingsView(
            settings: settings,
            hotkeyService: hotkeyService,
            clearHistory: clearHistory
        )
        let hostingController = NSHostingController(rootView: view)
        let window = NSWindow(contentViewController: hostingController)
        window.title = "AnythingBar 設定"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.setContentSize(NSSize(width: 500, height: 410))
        window.isReleasedWhenClosed = false
        window.center()
        super.init(window: window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    func show() {
        guard let window else { return }
        NSApplication.shared.activate(ignoringOtherApps: true)
        window.center()
        showWindow(nil)
        window.makeKeyAndOrderFront(nil)
    }
}
