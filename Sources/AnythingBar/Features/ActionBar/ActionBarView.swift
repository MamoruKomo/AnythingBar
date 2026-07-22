import AnythingBarCore
import SwiftUI

struct ActionBarView: View {
    @ObservedObject var model: ActionBarViewModel
    @FocusState private var searchIsFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            ContentPreviewView(content: model.content)

            Divider()

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("操作を検索", text: $model.query)
                    .textFieldStyle(.plain)
                    .font(.system(size: 16))
                    .focused($searchIsFocused)

                if !model.query.isEmpty {
                    Text("⌘Aで選択")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 48)

            Divider()

            actionList

            Divider()

            ActionBarFooter(status: model.status)
        }
        .frame(width: 620)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(.separator.opacity(0.7), lineWidth: 1)
        }
        .onAppear {
            searchIsFocused = true
        }
    }

    @ViewBuilder
    private var actionList: some View {
        if model.filteredActions.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: model.content == nil ? "exclamationmark.triangle" : "magnifyingglass")
                    .font(.title3)
                    .foregroundStyle(model.status?.isError == true ? .red : .secondary)
                Text(model.content == nil ? "内容を取得できません" : "一致する操作がありません")
                    .font(.callout.weight(.medium))
                if model.content != nil {
                    Text("別の検索語を入力してください。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 92)
        } else {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(Array(model.filteredActions.enumerated()), id: \.element.id) { index, action in
                            ActionRow(
                                action: action,
                                isSelected: index == model.selectedIndex
                            ) {
                                model.select(index: index)
                                model.executeSelected()
                            }
                            .id(action.id)
                        }
                    }
                    .padding(6)
                }
                .frame(height: listHeight)
                .onChange(of: model.selectedIndex) { _, newIndex in
                    guard model.filteredActions.indices.contains(newIndex) else { return }
                    proxy.scrollTo(model.filteredActions[newIndex].id, anchor: .center)
                }
            }
        }
    }

    private var listHeight: CGFloat {
        CGFloat(min(max(model.filteredActions.count, 1), 5)) * 50 + 12
    }
}

private struct ContentPreviewView: View {
    let content: CapturedContent?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: content?.type.kind.symbolName ?? "command.square")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.tint)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 5) {
                Text(content?.type.kind.displayName ?? "AnythingBar")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(content?.normalizedValue ?? "クリップボードのテキストから操作を選びます")
                    .font(.system(size: 14))
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(minHeight: 68)
    }
}

private struct ActionRow: View {
    let action: ActionItem
    let isSelected: Bool
    let perform: () -> Void

    var body: some View {
        Button(action: perform) {
            HStack(spacing: 12) {
                Image(systemName: action.symbolName)
                    .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(action.title)
                        .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                        .lineLimit(1)

                    if let subtitle = action.subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(isSelected ? Color.primary.opacity(0.75) : Color.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }

                Spacer(minLength: 8)

                if isSelected {
                    Text("↩")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
            .contentShape(Rectangle())
            .background {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.17) : .clear)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct ActionBarFooter: View {
    let status: ActionBarStatus?

    var body: some View {
        HStack(spacing: 8) {
            if let status {
                Image(systemName: status.isError ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
                    .foregroundStyle(status.isError ? .red : .green)
                Text(status.text)
                    .lineLimit(2)
            } else {
                Text("↑↓ 選択  ·  ↩ 実行  ·  esc 閉じる")
            }

            Spacer(minLength: 8)

            Text("⌘C 内容をコピー")
                .foregroundStyle(.secondary)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 14)
        .frame(minHeight: 34)
    }
}
