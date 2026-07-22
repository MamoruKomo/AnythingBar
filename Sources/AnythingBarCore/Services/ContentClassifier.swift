import Foundation

public protocol ContentClassifying: Sendable {
    func classify(
        _ rawValue: String,
        id: UUID,
        capturedAt: Date
    ) -> CapturedContent
}

public struct ContentClassifier: ContentClassifying, Sendable {
    private static let emailPattern =
        #"^[A-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[A-Z0-9](?:[A-Z0-9-]{0,61}[A-Z0-9])?(?:\.[A-Z0-9](?:[A-Z0-9-]{0,61}[A-Z0-9])?)+$"#

    public init() {}

    public func classify(
        _ rawValue: String,
        id: UUID = UUID(),
        capturedAt: Date = Date()
    ) -> CapturedContent {
        let normalizedValue = ContentNormalizer.normalize(rawValue)

        return CapturedContent(
            id: id,
            rawValue: rawValue,
            normalizedValue: normalizedValue,
            type: classifyNormalized(normalizedValue),
            capturedAt: capturedAt
        )
    }

    private func classifyNormalized(_ value: String) -> ContentType {
        if let url = webURL(from: value) {
            return .url(url)
        }

        if isEmail(value) {
            return .email(value)
        }

        if value.range(of: #"^[0-9]{4}$"#, options: .regularExpression) != nil {
            return .japaneseStockCode(value)
        }

        return .plainText(value)
    }

    private func webURL(from value: String) -> URL? {
        guard
            let url = URL(string: value),
            let scheme = url.scheme?.lowercased(),
            scheme == "http" || scheme == "https",
            let host = url.host,
            !host.isEmpty
        else {
            return nil
        }

        return url
    }

    private func isEmail(_ value: String) -> Bool {
        value.range(
            of: Self.emailPattern,
            options: [.regularExpression, .caseInsensitive]
        ) != nil
    }
}
