import Testing
@testable import AnythingBarCore

@Suite("SearchURLBuilder")
struct SearchURLBuilderTests {
    private let builder = SearchURLBuilder()

    @Test("検索語をパーセントエンコードする")
    func percentEncodesSearchQuery() throws {
        let url = try builder.googleURL(query: "Swift 日本語 & test")

        #expect(
            url.absoluteString ==
                "https://www.google.com/search?q=Swift%20%E6%97%A5%E6%9C%AC%E8%AA%9E%20%26%20test"
        )
    }

    @Test("空の検索語は明確なエラーにする")
    func rejectsEmptyQuery() {
        #expect(throws: SearchURLBuilderError.emptyQuery) {
            try builder.googleURL(query: " \n ")
        }
    }
}
