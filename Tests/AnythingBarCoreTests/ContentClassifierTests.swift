import Testing
@testable import AnythingBarCore

@Suite("ContentClassifier")
struct ContentClassifierTests {
    private let classifier = ContentClassifier()

    @Test("http/https URLを判定する", arguments: [
        "https://example.com/path?q=1",
        "http://example.jp"
    ])
    func classifiesURL(_ input: String) {
        let captured = classifier.classify(input)

        guard case let .url(url) = captured.type else {
            Issue.record("URLとして分類されませんでした")
            return
        }
        #expect(url.absoluteString == input)
    }

    @Test("不正なURLを通常テキストにする", arguments: [
        "ftp://example.com",
        "https://",
        "https://exa mple.com"
    ])
    func rejectsInvalidURL(_ input: String) {
        #expect(classifier.classify(input).type == .plainText(input))
    }

    @Test("メールアドレスを判定する")
    func classifiesEmail() {
        let input = "person+alerts@example.co.jp"
        #expect(classifier.classify(input).type == .email(input))
    }

    @Test("不正なメールアドレスを通常テキストにする", arguments: [
        "person@",
        "@example.com",
        "person@example"
    ])
    func rejectsInvalidEmail(_ input: String) {
        #expect(classifier.classify(input).type == .plainText(input))
    }

    @Test("4桁の半角数字を日本株の証券コードにする")
    func classifiesJapaneseStockCode() {
        #expect(classifier.classify("7203").type == .japaneseStockCode("7203"))
    }

    @Test("3桁・5桁の数字を証券コードにしない", arguments: ["123", "12345"])
    func rejectsWrongLengthStockCode(_ input: String) {
        #expect(classifier.classify(input).type == .plainText(input))
    }

    @Test("前後の空白と改行を除去する")
    func trimsOuterWhitespace() {
        let captured = classifier.classify("  \n7203\t ")

        #expect(captured.normalizedValue == "7203")
        #expect(captured.type == .japaneseStockCode("7203"))
    }

    @Test("未対応の内容を通常テキストへフォールバックする")
    func fallsBackToPlainText() {
        let input = "明日の会議メモ"
        #expect(classifier.classify(input).type == .plainText(input))
    }
}
