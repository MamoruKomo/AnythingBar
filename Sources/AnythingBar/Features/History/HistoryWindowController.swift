import AnythingBarCore
import AppKit
import SwiftUI

@MainActor
final class HistoryWindowController: NSWindowController {
    let model: HistoryViewModel

    init(store: JSONHistoryStore) {
        model = HistoryViewModel(store: store)
        let hostingController = NSHostingController(rootView: HistoryView(model: model))
        let window = NSWindow(contentViewController: hostingController)
        window.title = "AnythingBar 履歴"
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.setContentSize(NSSize(width: 680, height: 520))
        window.minSize = NSSize(width: 620, height: 460)
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
        model.reload()
        NSApplication.shared.activate(ignoringOtherApps: true)
        showWindow(nil)
        window.makeKeyAndOrderFront(nil)
    }
}
