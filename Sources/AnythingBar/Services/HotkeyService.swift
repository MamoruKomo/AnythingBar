import AppKit
import Combine
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let openAnythingBar = Self(
        "openAnythingBar",
        initial: KeyboardShortcuts.Shortcut(
            .space,
            modifiers: [.command, .shift]
        )
    )
}

@MainActor
final class HotkeyService: ObservableObject {
    @Published private(set) var conflictMessage: String?

    private let onTrigger: () -> Void

    init(onTrigger: @escaping () -> Void) {
        self.onTrigger = onTrigger

        KeyboardShortcuts.onKeyUp(for: .openAnythingBar) { [weak self] in
            self?.onTrigger()
        }
        validateShortcut()
    }

    func validateShortcut() {
        guard let shortcut = KeyboardShortcuts.Shortcut(name: .openAnythingBar) else {
            conflictMessage = "グローバルショートカットが設定されていません。設定画面で登録してください。"
            return
        }

        if shortcut.isTakenBySystem {
            conflictMessage = "このショートカットはmacOSの機能と競合しています。設定画面で別の組み合わせを選択してください。"
        } else {
            conflictMessage = nil
        }
    }
}
