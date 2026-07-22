import Foundation

public struct ClipboardPayload: Equatable, Sendable {
    public let rawValue: String
    public let normalizedValue: String

    public init(rawValue: String, normalizedValue: String) {
        self.rawValue = rawValue
        self.normalizedValue = normalizedValue
    }
}

public enum ClipboardReadError: Error, Equatable, LocalizedError, Sendable {
    case empty
    case nonText

    public var errorDescription: String? {
        switch self {
        case .empty:
            "クリップボードが空です"
        case .nonText:
            "文字列以外がコピーされています"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .empty:
            "別のアプリでテキストをコピーしてから、もう一度ショートカットを押してください。"
        case .nonText:
            "画像やファイルではなく、テキストをコピーしてから再実行してください。"
        }
    }
}
