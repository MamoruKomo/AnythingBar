import AnythingBarCore
import KeyboardShortcuts
import SwiftUI

private struct SettingsStatus {
    let text: String
    let isError: Bool
}

struct SettingsView: View {
    @ObservedObject var settings: SettingsStore
    @ObservedObject var hotkeyService: HotkeyService
    let clearHistory: () -> Result<Void, HistoryStoreError>

    @State private var confirmsClear = false
    @State private var clearStatus: SettingsStatus?

    var body: some View {
        Form {
            Section("グローバルショートカット") {
                KeyboardShortcuts.Recorder(
                    "AnythingBarを開く",
                    name: .openAnythingBar
                ) { _ in
                    hotkeyService.validateShortcut()
                }

                if let conflictMessage = hotkeyService.conflictMessage {
                    Label(conflictMessage, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                } else {
                    Text("初期設定は Command＋Shift＋Space です。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("履歴とプライバシー") {
                Toggle("ローカル履歴を保存", isOn: $settings.historyEnabled)
                Toggle("メールアドレスも履歴に保存", isOn: $settings.emailHistoryEnabled)
                    .disabled(!settings.historyEnabled)

                Button("履歴をすべて削除…", role: .destructive) {
                    confirmsClear = true
                }

                if let clearStatus {
                    Label(
                        clearStatus.text,
                        systemImage: clearStatus.isError ? "exclamationmark.circle" : "checkmark.circle"
                    )
                    .font(.caption)
                    .foregroundStyle(clearStatus.isError ? .red : .green)
                }

                Text("履歴はMac内のJSONファイルに最大50件だけ保存します。外部への送信は行いません。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("選択中のテキスト") {
                Label(
                    "Accessibility APIによる選択テキスト取得は今後追加予定です。MVPではクリップボードを使用します。",
                    systemImage: "accessibility"
                )
                .font(.callout)
            }
        }
        .formStyle(.grouped)
        .padding(8)
        .frame(width: 500, height: 410)
        .alert("履歴をすべて削除しますか？", isPresented: $confirmsClear) {
            Button("削除", role: .destructive) {
                handleClearHistory()
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("この操作は取り消せません。")
        }
    }

    private func handleClearHistory() {
        switch clearHistory() {
        case .success:
            clearStatus = SettingsStatus(text: "履歴を削除しました", isError: false)
        case let .failure(error):
            let description = error.errorDescription ?? "履歴を削除できませんでした"
            let recovery = error.recoverySuggestion ?? "保存先を確認して再試行してください。"
            clearStatus = SettingsStatus(text: "\(description)。\(recovery)", isError: true)
        }
    }
}
