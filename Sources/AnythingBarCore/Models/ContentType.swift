import Foundation

public enum ContentKind: String, Codable, CaseIterable, Equatable, Sendable {
    case url
    case email
    case japaneseStockCode
    case plainText

    public var displayName: String {
        switch self {
        case .url:
            "URL"
        case .email:
            "メールアドレス"
        case .japaneseStockCode:
            "日本株の証券コード"
        case .plainText:
            "テキスト"
        }
    }

    public var symbolName: String {
        switch self {
        case .url:
            "link"
        case .email:
            "envelope"
        case .japaneseStockCode:
            "chart.line.uptrend.xyaxis"
        case .plainText:
            "text.alignleft"
        }
    }
}

public enum ContentType: Equatable, Sendable {
    case url(URL)
    case email(String)
    case japaneseStockCode(String)
    case plainText(String)

    public var kind: ContentKind {
        switch self {
        case .url:
            .url
        case .email:
            .email
        case .japaneseStockCode:
            .japaneseStockCode
        case .plainText:
            .plainText
        }
    }

    public var value: String {
        switch self {
        case let .url(url):
            url.absoluteString
        case let .email(value),
             let .japaneseStockCode(value),
             let .plainText(value):
            value
        }
    }
}
