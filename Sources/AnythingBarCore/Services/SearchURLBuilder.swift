import Foundation

public enum SearchURLBuilderError: Error, Equatable, LocalizedError, Sendable {
    case emptyQuery
    case invalidURL

    public var errorDescription: String? {
        switch self {
        case .emptyQuery:
            "検索語が空です"
        case .invalidURL:
            "検索URLを生成できませんでした"
        }
    }
}

public struct SearchURLBuilder: Sendable {
    private static let googleScheme = "https"
    private static let googleHost = "www.google.com"
    private static let googlePath = "/search"

    public init() {}

    public func googleURL(query: String) throws(SearchURLBuilderError) -> URL {
        try makeGoogleURL(query: query)
    }

    public func stockIRURL(code: String) throws(SearchURLBuilderError) -> URL {
        try makeGoogleURL(query: "\(code) 企業 IR")
    }

    public func tdnetURL(code: String) throws(SearchURLBuilderError) -> URL {
        try makeGoogleURL(query: "site:release.tdnet.info \(code) TDnet")
    }

    public func edinetURL(code: String) throws(SearchURLBuilderError) -> URL {
        try makeGoogleURL(query: "site:disclosure2.edinet-fsa.go.jp \(code) EDINET")
    }

    public func mailtoURL(address: String) throws(SearchURLBuilderError) -> URL {
        guard !ContentNormalizer.normalize(address).isEmpty else {
            throw SearchURLBuilderError.emptyQuery
        }

        var components = URLComponents()
        components.scheme = "mailto"
        components.path = address

        guard let url = components.url else {
            throw SearchURLBuilderError.invalidURL
        }
        return url
    }

    private func makeGoogleURL(query: String) throws(SearchURLBuilderError) -> URL {
        let normalizedQuery = ContentNormalizer.normalize(query)
        guard !normalizedQuery.isEmpty else {
            throw SearchURLBuilderError.emptyQuery
        }

        var components = URLComponents()
        components.scheme = Self.googleScheme
        components.host = Self.googleHost
        components.path = Self.googlePath
        components.queryItems = [
            URLQueryItem(name: "q", value: normalizedQuery)
        ]

        guard let url = components.url else {
            throw SearchURLBuilderError.invalidURL
        }
        return url
    }
}
