import AnythingBarCore
import Combine

@MainActor
final class HistoryViewModel: ObservableObject {
    @Published private(set) var entries: [HistoryEntry] = []
    @Published private(set) var errorMessage: String?

    private let store: JSONHistoryStore

    init(store: JSONHistoryStore) {
        self.store = store
        reload()
    }

    func reload() {
        do {
            entries = try store.load()
            errorMessage = nil
        } catch {
            errorMessage = Self.message(for: error)
        }
    }

    func clear() {
        do {
            try store.clear()
            entries = []
            errorMessage = nil
        } catch {
            errorMessage = Self.message(for: error)
        }
    }

    private static func message(for error: HistoryStoreError) -> String {
        let description = error.errorDescription ?? "履歴を操作できませんでした"
        let recovery = error.recoverySuggestion ?? "保存先を確認して再試行してください。"
        return "\(description)。\(recovery)"
    }
}
