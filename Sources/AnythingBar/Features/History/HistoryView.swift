import AnythingBarCore
import SwiftUI

struct HistoryView: View {
    @ObservedObject var model: HistoryViewModel
    @State private var confirmsClear = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("履歴")
                        .font(.title2.weight(.semibold))
                    Text("このMacに保存された直近50件")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button("すべて削除", role: .destructive) {
                    confirmsClear = true
                }
                .disabled(model.entries.isEmpty)
            }
            .padding(16)

            Divider()

            if let errorMessage = model.errorMessage {
                VStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.title2)
                        .foregroundStyle(.orange)
                    Text(errorMessage)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                    Button("再読み込み") {
                        model.reload()
                    }
                }
                .padding(32)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if model.entries.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.largeTitle)
                        .foregroundStyle(.tertiary)
                    Text("履歴はまだありません")
                        .font(.headline)
                    Text("操作を実行すると、設定に従ってローカルに保存されます。")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(model.entries) { entry in
                    HistoryRow(entry: entry)
                }
                .listStyle(.inset)
            }
        }
        .frame(minWidth: 620, minHeight: 460)
        .alert("履歴をすべて削除しますか？", isPresented: $confirmsClear) {
            Button("削除", role: .destructive) {
                model.clear()
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("この操作は取り消せません。")
        }
        .onAppear {
            model.reload()
        }
    }
}

private struct HistoryRow: View {
    let entry: HistoryEntry

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: entry.contentKind.symbolName)
                .foregroundStyle(.tint)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 5) {
                Text(entry.normalizedValue)
                    .font(.system(size: 14, weight: .medium))
                    .lineLimit(2)
                    .truncationMode(.tail)

                HStack(spacing: 6) {
                    Text(entry.contentKind.displayName)
                    Text("·")
                    Text(entry.actionTitle)
                    Text("·")
                    Text(entry.executedAt.formatted(date: .abbreviated, time: .shortened))
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)
        }
        .padding(.vertical, 5)
    }
}
