import AnythingBarCore
import AppKit

@MainActor
protocol WorkspaceOpening {
    func open(_ url: URL) -> Bool
}

@MainActor
struct SystemWorkspaceOpener: WorkspaceOpening {
    func open(_ url: URL) -> Bool {
        NSWorkspace.shared.open(url)
    }
}

@MainActor
protocol PasteboardWriting {
    func writeString(_ value: String) -> Bool
}

@MainActor
struct SystemPasteboardWriter: PasteboardWriting {
    private let pasteboard: NSPasteboard

    init(pasteboard: NSPasteboard = .general) {
        self.pasteboard = pasteboard
    }

    func writeString(_ value: String) -> Bool {
        pasteboard.clearContents()
        return pasteboard.setString(value, forType: .string)
    }
}

struct ActionExecutionOutcome: Equatable {
    let message: String?
    let shouldClose: Bool

    static let completed = ActionExecutionOutcome(message: nil, shouldClose: true)
}

enum ActionExecutionError: Error, LocalizedError, Equatable {
    case unsupportedAction
    case cannotOpenURL(String)
    case copyFailed
    case searchURLGenerationFailed
    case missingDomain

    var errorDescription: String? {
        switch self {
        case .unsupportedAction:
            "この内容では選択した操作を実行できません"
        case .cannotOpenURL:
            "URLを開けませんでした"
        case .copyFailed:
            "クリップボードへのコピーに失敗しました"
        case .searchURLGenerationFailed:
            "検索URLの生成に失敗しました"
        case .missingDomain:
            "ドメイン名を取得できませんでした"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .unsupportedAction:
            "操作バーを開き直して、別の操作を選択してください。"
        case let .cannotOpenURL(url):
            "既定アプリの設定を確認してください。対象: \(url)"
        case .copyFailed:
            "クリップボードを使用しているアプリを閉じてから再試行してください。"
        case .searchURLGenerationFailed:
            "検索語を確認し、もう一度操作を実行してください。"
        case .missingDomain:
            "URLまたはメールアドレスの形式を確認してください。"
        }
    }
}

@MainActor
final class ActionExecutor<Workspace: WorkspaceOpening, Pasteboard: PasteboardWriting> {
    private let workspace: Workspace
    private let pasteboard: Pasteboard
    private let urlBuilder: SearchURLBuilder

    init(
        workspace: Workspace,
        pasteboard: Pasteboard,
        urlBuilder: SearchURLBuilder = SearchURLBuilder()
    ) {
        self.workspace = workspace
        self.pasteboard = pasteboard
        self.urlBuilder = urlBuilder
    }

    func execute(
        _ action: ActionItem,
        for content: CapturedContent
    ) throws(ActionExecutionError) -> ActionExecutionOutcome {
        switch (action.actionID, content.type) {
        case let (.openURL, .url(url)):
            return try open(url)
        case let (.copyURL, .url(url)):
            return try copy(url.absoluteString)
        case let (.copyMarkdownLink, .url(url)):
            guard let domain = url.host, !domain.isEmpty else {
                throw ActionExecutionError.missingDomain
            }
            return try copy("[\(domain)](\(url.absoluteString))")
        case let (.copyURLDomain, .url(url)):
            guard let domain = url.host, !domain.isEmpty else {
                throw ActionExecutionError.missingDomain
            }
            return try copy(domain)
        case let (.composeEmail, .email(address)):
            return try openGeneratedURL { () throws(SearchURLBuilderError) -> URL in
                try urlBuilder.mailtoURL(address: address)
            }
        case let (.copyEmail, .email(address)):
            return try copy(address)
        case let (.copyEmailDomain, .email(address)):
            guard let domain = address.split(separator: "@", maxSplits: 1).last else {
                throw ActionExecutionError.missingDomain
            }
            return try copy(String(domain))
        case let (.searchStockIR, .japaneseStockCode(code)):
            return try openGeneratedURL { () throws(SearchURLBuilderError) -> URL in
                try urlBuilder.stockIRURL(code: code)
            }
        case let (.searchTDnet, .japaneseStockCode(code)):
            return try openGeneratedURL { () throws(SearchURLBuilderError) -> URL in
                try urlBuilder.tdnetURL(code: code)
            }
        case let (.searchEDINET, .japaneseStockCode(code)):
            return try openGeneratedURL { () throws(SearchURLBuilderError) -> URL in
                try urlBuilder.edinetURL(code: code)
            }
        case let (.copyStockCode, .japaneseStockCode(code)):
            return try copy(code)
        case let (.googleSearch, .plainText(text)):
            return try openGeneratedURL { () throws(SearchURLBuilderError) -> URL in
                try urlBuilder.googleURL(query: text)
            }
        case let (.copyText, .plainText(text)):
            return try copy(text)
        case let (.showCharacterCount, .plainText(text)):
            return ActionExecutionOutcome(
                message: "\(text.count)文字です",
                shouldClose: false
            )
        case (.saveToHistory, .plainText):
            return ActionExecutionOutcome(
                message: nil,
                shouldClose: false
            )
        default:
            throw ActionExecutionError.unsupportedAction
        }
    }

    func copyCurrentContent(
        _ content: CapturedContent
    ) throws(ActionExecutionError) -> ActionExecutionOutcome {
        try copy(content.normalizedValue)
    }

    private func openGeneratedURL(
        _ makeURL: () throws(SearchURLBuilderError) -> URL
    ) throws(ActionExecutionError) -> ActionExecutionOutcome {
        let url: URL
        do {
            url = try makeURL()
        } catch {
            throw ActionExecutionError.searchURLGenerationFailed
        }
        return try open(url)
    }

    private func open(_ url: URL) throws(ActionExecutionError) -> ActionExecutionOutcome {
        guard workspace.open(url) else {
            throw ActionExecutionError.cannotOpenURL(url.absoluteString)
        }
        return .completed
    }

    private func copy(_ value: String) throws(ActionExecutionError) -> ActionExecutionOutcome {
        guard pasteboard.writeString(value) else {
            throw ActionExecutionError.copyFailed
        }
        return ActionExecutionOutcome(message: "コピーしました", shouldClose: true)
    }
}

extension ActionExecutor where Workspace == SystemWorkspaceOpener, Pasteboard == SystemPasteboardWriter {
    convenience init() {
        self.init(
            workspace: SystemWorkspaceOpener(),
            pasteboard: SystemPasteboardWriter()
        )
    }
}
