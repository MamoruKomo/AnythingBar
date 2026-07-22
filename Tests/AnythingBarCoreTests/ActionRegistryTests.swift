import Testing
@testable import AnythingBarCore

@Suite("ActionRegistry")
struct ActionRegistryTests {
    private let classifier = ContentClassifier()
    private let registry = ActionRegistry()

    @Test("URL向け操作を返す")
    func urlActions() {
        let type = classifier.classify("https://example.com/docs").type
        #expect(registry.actions(for: type).map(\.actionID) == [
            .openURL,
            .copyURL,
            .copyMarkdownLink,
            .copyURLDomain
        ])
    }

    @Test("メールアドレス向け操作を返す")
    func emailActions() {
        let type = classifier.classify("hello@example.com").type
        #expect(registry.actions(for: type).map(\.actionID) == [
            .composeEmail,
            .copyEmail,
            .copyEmailDomain
        ])
    }

    @Test("証券コード向け操作を返す")
    func stockActions() {
        let type = classifier.classify("7203").type
        #expect(registry.actions(for: type).map(\.actionID) == [
            .searchStockIR,
            .searchTDnet,
            .searchEDINET,
            .copyStockCode
        ])
    }

    @Test("通常テキスト向け操作を返す")
    func plainTextActions() {
        let type = classifier.classify("AnythingBar MVP").type
        #expect(registry.actions(for: type).map(\.actionID) == [
            .googleSearch,
            .copyText,
            .showCharacterCount,
            .saveToHistory
        ])
    }

    @Test("タイトル・サブタイトル・keywordsで絞り込める")
    func actionFiltering() {
        let actions = registry.actions(for: classifier.classify("7203").type)

        #expect(actions.filter { $0.matches(query: "適時開示") }.map(\.actionID) == [.searchTDnet])
        #expect(actions.filter { $0.matches(query: "7203") }.count == 4)
        #expect(actions.filter { $0.matches(query: "copy") }.map(\.actionID) == [.copyStockCode])
    }
}
