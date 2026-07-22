import Foundation

public protocol ActionRegistering: Sendable {
    func actions(for contentType: ContentType) -> [ActionItem]
}

public struct ActionRegistry: ActionRegistering, Sendable {
    public init() {}

    public func actions(for contentType: ContentType) -> [ActionItem] {
        switch contentType {
        case let .url(url):
            urlActions(url)
        case let .email(address):
            emailActions(address)
        case let .japaneseStockCode(code):
            stockActions(code)
        case let .plainText(text):
            textActions(text)
        }
    }

    private func urlActions(_ url: URL) -> [ActionItem] {
        let domain = url.host ?? "ドメインを取得できません"
        return [
            ActionItem(
                id: .openURL,
                title: "デフォルトブラウザで開く",
                subtitle: url.absoluteString,
                symbolName: "safari",
                keywords: ["open", "browser", "開く", "ブラウザ"]
            ),
            ActionItem(
                id: .copyURL,
                title: "URLをコピー",
                symbolName: "doc.on.doc",
                keywords: ["copy", "url", "コピー"]
            ),
            ActionItem(
                id: .copyMarkdownLink,
                title: "Markdownリンク形式でコピー",
                subtitle: "[\(domain)](\(url.absoluteString))",
                symbolName: "link",
                keywords: ["markdown", "md", "link", "コピー"]
            ),
            ActionItem(
                id: .copyURLDomain,
                title: "ドメイン名だけコピー",
                subtitle: domain,
                symbolName: "network",
                keywords: ["domain", "host", "ドメイン", "コピー"]
            )
        ]
    }

    private func emailActions(_ address: String) -> [ActionItem] {
        let domain = address.split(separator: "@", maxSplits: 1).last.map(String.init)
        return [
            ActionItem(
                id: .composeEmail,
                title: "新規メールを作成",
                subtitle: address,
                symbolName: "envelope.badge",
                keywords: ["mail", "email", "compose", "メール", "送信"]
            ),
            ActionItem(
                id: .copyEmail,
                title: "メールアドレスをコピー",
                symbolName: "doc.on.doc",
                keywords: ["copy", "email", "address", "コピー"]
            ),
            ActionItem(
                id: .copyEmailDomain,
                title: "ドメイン部分をコピー",
                subtitle: domain,
                symbolName: "at",
                keywords: ["domain", "host", "ドメイン", "コピー"]
            )
        ]
    }

    private func stockActions(_ code: String) -> [ActionItem] {
        [
            ActionItem(
                id: .searchStockIR,
                title: "企業IRをGoogleで検索",
                subtitle: "\(code) 企業 IR",
                symbolName: "magnifyingglass",
                keywords: ["google", "ir", "企業", "検索"]
            ),
            ActionItem(
                id: .searchTDnet,
                title: "TDnetを検索",
                subtitle: code,
                symbolName: "doc.text.magnifyingglass",
                keywords: ["tdnet", "適時開示", "検索"]
            ),
            ActionItem(
                id: .searchEDINET,
                title: "EDINETを検索",
                subtitle: code,
                symbolName: "building.columns",
                keywords: ["edinet", "有価証券報告書", "検索"]
            ),
            ActionItem(
                id: .copyStockCode,
                title: "証券コードをコピー",
                subtitle: code,
                symbolName: "doc.on.doc",
                keywords: ["copy", "code", "証券", "コピー"]
            )
        ]
    }

    private func textActions(_ text: String) -> [ActionItem] {
        [
            ActionItem(
                id: .googleSearch,
                title: "Google検索",
                subtitle: text,
                symbolName: "magnifyingglass",
                keywords: ["google", "web", "検索"]
            ),
            ActionItem(
                id: .copyText,
                title: "テキストをコピー",
                symbolName: "doc.on.doc",
                keywords: ["copy", "text", "コピー"]
            ),
            ActionItem(
                id: .showCharacterCount,
                title: "文字数を表示",
                subtitle: "\(text.count)文字",
                symbolName: "character.cursor.ibeam",
                keywords: ["count", "length", "文字数"]
            ),
            ActionItem(
                id: .saveToHistory,
                title: "ローカルの履歴に保存",
                symbolName: "clock.arrow.circlepath",
                keywords: ["save", "history", "履歴", "保存"]
            )
        ]
    }
}
