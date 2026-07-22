import Testing
@testable import AnythingBarCore

@Suite("JSONHistoryStore", .serialized)
struct JSONHistoryStoreTests {
    private let classifier = ContentClassifier()
    private let registry = ActionRegistry()
    private let policy = HistoryPolicy(isEnabled: true, savesEmailAddresses: true)

    @Test("直近50件だけを保存する")
    func limitsHistoryToFiftyEntries() throws {
        let store = JSONHistoryStore(
            filePath: "/tmp/AnythingBarTests-history-limit.json",
            maximumEntryCount: 50
        )
        try store.clear()

        for index in 0..<60 {
            let content = classifier.classify("entry \(index)")
            let action = registry.actions(for: content.type)[0]
            try store.record(content: content, action: action, policy: policy)
        }

        let entries = try store.load()
        #expect(entries.count == 50)
        #expect(entries.first?.normalizedValue == "entry 59")
        #expect(entries.last?.normalizedValue == "entry 10")
        try store.clear()
    }

    @Test("同じ内容を連続して重複保存しない")
    func preventsConsecutiveDuplicates() throws {
        let store = JSONHistoryStore(
            filePath: "/tmp/AnythingBarTests-history-duplicate.json"
        )
        try store.clear()

        let content = classifier.classify("same content")
        let actions = registry.actions(for: content.type)

        let firstResult = try store.record(
            content: content,
            action: actions[0],
            policy: policy
        )
        let secondResult = try store.record(
            content: content,
            action: actions[1],
            policy: policy
        )

        #expect(firstResult == .saved)
        #expect(secondResult == .skippedDuplicate)
        #expect(try store.load().count == 1)
        try store.clear()
    }
}
