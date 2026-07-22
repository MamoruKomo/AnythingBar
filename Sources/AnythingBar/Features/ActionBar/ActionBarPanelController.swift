import AnythingBarCore
import AppKit
import SwiftUI

@MainActor
final class ActionBarPanelController {
    private var panel: ActionBarPanel?
    private var hostingController: NSHostingController<ActionBarView>?
    private(set) var model: ActionBarViewModel?

    func show(
        content: CapturedContent,
        actions: [ActionItem],
        onExecute: @escaping (ActionItem) -> Void,
        onCopyCurrentContent: @escaping () -> Void
    ) {
        let model = ActionBarViewModel(content: content, actions: actions)
        model.onExecute = onExecute
        model.onCopyCurrentContent = onCopyCurrentContent
        model.onDismiss = { [weak self] in
            self?.close()
        }
        present(model)
    }

    func show(error: ClipboardReadError) {
        let description = error.errorDescription ?? "クリップボードを読み取れませんでした"
        let recovery = error.recoverySuggestion ?? "テキストをコピーしてから再試行してください。"
        let model = ActionBarViewModel(
            content: nil,
            actions: [],
            status: ActionBarStatus(
                text: "\(description)。\(recovery)",
                isError: true
            )
        )
        model.onDismiss = { [weak self] in
            self?.close()
        }
        present(model)
    }

    func setStatus(_ text: String, isError: Bool) {
        model?.setStatus(text, isError: isError)
    }

    func close() {
        panel?.orderOut(nil)
        model = nil
        hostingController = nil
    }

    private func present(_ model: ActionBarViewModel) {
        self.model = model

        let rootView = ActionBarView(model: model)
        let hostingController = NSHostingController(rootView: rootView)
        self.hostingController = hostingController

        let size = panelSize(for: model)
        let panel = panel ?? makePanel(size: size)
        self.panel = panel

        panel.setContentSize(size)
        panel.contentViewController = hostingController
        panel.onMoveUp = { [weak model] in model?.moveSelection(by: -1) }
        panel.onMoveDown = { [weak model] in model?.moveSelection(by: 1) }
        panel.onExecute = { [weak model] in model?.executeSelected() }
        panel.onDismiss = { [weak model] in model?.onDismiss() }
        panel.onCopy = { [weak model] in model?.onCopyCurrentContent() }

        center(panel)
        NSApplication.shared.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
    }

    private func makePanel(size: NSSize) -> ActionBarPanel {
        let panel = ActionBarPanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isMovable = false
        panel.isReleasedWhenClosed = false
        panel.animationBehavior = .utilityWindow
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        return panel
    }

    private func panelSize(for model: ActionBarViewModel) -> NSSize {
        let rowCount = min(max(model.actions.count, 1), 5)
        let height = model.content == nil ? 244 : CGFloat(68 + 49 + 1 + rowCount * 50 + 12 + 35)
        return NSSize(width: 620, height: height)
    }

    private func center(_ panel: NSPanel) {
        let mouseLocation = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { $0.frame.contains(mouseLocation) } ?? NSScreen.main
        guard let visibleFrame = screen?.visibleFrame else {
            panel.center()
            return
        }

        let origin = NSPoint(
            x: visibleFrame.midX - panel.frame.width / 2,
            y: visibleFrame.midY - panel.frame.height / 2
        )
        panel.setFrameOrigin(origin)
    }
}

private final class ActionBarPanel: NSPanel {
    var onMoveUp: () -> Void = {}
    var onMoveDown: () -> Void = {}
    var onExecute: () -> Void = {}
    var onDismiss: () -> Void = {}
    var onCopy: () -> Void = {}

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    override func keyDown(with event: NSEvent) {
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

        if modifiers.contains(.command), event.charactersIgnoringModifiers?.lowercased() == "c" {
            onCopy()
            return
        }

        switch event.keyCode {
        case 53:
            onDismiss()
        case 126:
            onMoveUp()
        case 125:
            onMoveDown()
        case 36, 76:
            if let editor = firstResponder as? NSTextView, editor.hasMarkedText() {
                super.keyDown(with: event)
            } else {
                onExecute()
            }
        default:
            super.keyDown(with: event)
        }
    }
}
