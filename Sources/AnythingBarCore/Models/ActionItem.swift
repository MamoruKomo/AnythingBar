import Foundation

public enum ActionID: String, Codable, CaseIterable, Equatable, Sendable {
    case openURL
    case copyURL
    case copyMarkdownLink
    case copyURLDomain
    case composeEmail
    case copyEmail
    case copyEmailDomain
    case searchStockIR
    case searchTDnet
    case searchEDINET
    case copyStockCode
    case googleSearch
    case copyText
    case showCharacterCount
    case saveToHistory
}

public struct ActionItem: Identifiable, Equatable, Sendable {
    public let actionID: ActionID
    public let title: String
    public let subtitle: String?
    public let symbolName: String
    public let keywords: [String]

    public var id: String { actionID.rawValue }

    public init(
        id: ActionID,
        title: String,
        subtitle: String? = nil,
        symbolName: String,
        keywords: [String] = []
    ) {
        self.actionID = id
        self.title = title
        self.subtitle = subtitle
        self.symbolName = symbolName
        self.keywords = keywords
    }

    public func matches(query: String) -> Bool {
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedQuery.isEmpty else { return true }

        return ([title, subtitle].compactMap { $0 } + keywords)
            .contains { $0.localizedCaseInsensitiveContains(normalizedQuery) }
    }
}
