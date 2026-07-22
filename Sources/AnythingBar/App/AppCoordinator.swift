import AnythingBarCore
import AppKit

@MainActor
final class AppCoordinator {
    private let clipboardService = ClipboardService<SystemPasteboardReader>()
    private let classifier = ContentClassifier()
    private let actionRegistry = ActionRegistry()
    private let actionExecutor = ActionExecutor<SystemWorkspaceOpener, SystemPasteboardWriter>()
    private let panelController = ActionBarPanelController()
    private let settingsStore = SettingsStore()
    private let historyStore: JSONHistoryStore?
    private let historyInitializationError: HistoryStoreError?
    private var historyWindowController: HistoryWindowController?

    init() {
        do {
            let fileURL = try JSONHistoryStore.defaultFileURL()
            historyStore = JSONHistoryStore(fileURL: fileURL)
            historyInitializationError = nil
        } catch {
            historyStore = nil
            historyInitializationError = error
        }
    }

    private lazy var hotkeyService = HotkeyService { [weak self] in
        self?.openActionBar()
    }

    private lazy var settingsWindowController = SettingsWindowController(
        settings: settingsStore,
        hotkeyService: hotkeyService,
        clearHistory: { [weak self] in
            guard let self else {
                return .failure(.applicationSupportUnavailable)
            }
            return self.clearHistory()
        }
    )

    private lazy var menuBarController = MenuBarController(
        openActionBar: { [weak self] in self?.openActionBar() },
        openSettings: { [weak self] in self?.showSettings() },
        openHistory: { [weak self] in self?.showHistory() }
    )

    func start() {
        _ = hotkeyService
        _ = menuBarController
    }

    func openActionBar() {
        do {
            let payload = try clipboardService.readText()
            let content = classifier.classify(payload.rawValue)
            let actions = actionRegistry.actions(for: content.type)

            panelController.show(
                content: content,
                actions: actions,
                onExecute: { [weak self] action in
                    self?.execute(action, for: content)
                },
                onCopyCurrentContent: { [weak self] in
                    self?.copyCurrentContent(content)
                }
            )
        } catch {
            panelController.show(error: error)
        }
    }

    private func execute(_ action: ActionItem, for content: CapturedContent) {
        do {
            let outcome = try actionExecutor.execute(action, for: content)

            let historyResult: HistorySaveResult
            do {
                historyResult = try recordHistory(content: content, action: action)
            } catch {
                showHistoryError(error)
                return
            }

            if action.actionID == .saveToHistory {
                showExplicitHistoryResult(historyResult)
                return
            }

            if let message = outcome.message {
                panelController.setStatus(message, isError: false)
            }
            if outcome.shouldClose {
                panelController.close()
            }
        } catch {
            showExecutionError(error)
        }
    }

    private func copyCurrentContent(_ content: CapturedContent) {
        do {
            _ = try actionExecutor.copyCurrentContent(content)
            panelController.close()
        } catch {
            showExecutionError(error)
        }
    }

    private func showExecutionError(_ error: ActionExecutionError) {
        let description = error.errorDescription ?? "操作を実行できませんでした"
        let recovery = error.recoverySuggestion ?? "別の操作を選択して再試行してください。"
        panelController.setStatus("\(description)。\(recovery)", isError: true)
    }

    private func showSettings() {
        settingsWindowController.show()
    }

    private func showHistory() {
        guard let historyStore else {
            showHistoryUnavailableAlert()
            return
        }

        let controller: HistoryWindowController
        if let historyWindowController {
            controller = historyWindowController
        } else {
            controller = HistoryWindowController(store: historyStore)
            historyWindowController = controller
        }
        controller.show()
    }

    private func recordHistory(
        content: CapturedContent,
        action: ActionItem
    ) throws(HistoryStoreError) -> HistorySaveResult {
        let policy = HistoryPolicy(
            isEnabled: settingsStore.historyEnabled,
            savesEmailAddresses: settingsStore.emailHistoryEnabled
        )

        guard policy.isEnabled else {
            return .skippedDisabled
        }

        guard let historyStore else {
            throw historyInitializationError ?? HistoryStoreError.applicationSupportUnavailable
        }

        let result = try historyStore.record(
            content: content,
            action: action,
            policy: policy
        )
        if result == .saved {
            historyWindowController?.model.reload()
        }
        return result
    }

    private func clearHistory() -> Result<Void, HistoryStoreError> {
        guard let historyStore else {
            return .failure(historyInitializationError ?? .applicationSupportUnavailable)
        }

        do {
            try historyStore.clear()
            historyWindowController?.model.reload()
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    private func showExplicitHistoryResult(_ result: HistorySaveResult) {
        switch result {
        case .saved:
            panelController.setStatus("ローカルの履歴に保存しました", isError: false)
        case .skippedDisabled:
            panelController.setStatus(
                "履歴保存は設定で無効です。保存するには設定で有効にしてください。",
                isError: true
            )
        case .skippedEmail:
            panelController.setStatus(
                "メールアドレスの履歴保存は設定で無効です。",
                isError: true
            )
        case .skippedDuplicate:
            panelController.setStatus("同じ内容が直前にあるため、重複保存しませんでした", isError: false)
        }
    }

    private func showHistoryError(_ error: HistoryStoreError) {
        let description = error.errorDescription ?? "履歴を保存できませんでした"
        let recovery = error.recoverySuggestion ?? "保存先を確認して再試行してください。"
        panelController.setStatus("\(description)。\(recovery)", isError: true)
    }

    private func showHistoryUnavailableAlert() {
        let error = historyInitializationError ?? .applicationSupportUnavailable
        let alert = NSAlert()
        alert.messageText = error.errorDescription ?? "履歴を開けませんでした"
        alert.informativeText = error.recoverySuggestion ?? "保存先を確認して再試行してください。"
        alert.alertStyle = .warning
        alert.runModal()
    }
}
