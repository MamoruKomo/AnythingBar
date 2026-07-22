import Foundation

public enum HistoryStoreError: Error, LocalizedError, Sendable {
    case applicationSupportUnavailable
    case createDirectoryFailed(String)
    case readFailed(String)
    case decodeFailed(String)
    case writeFailed(String)
    case deleteFailed(String)

    public var errorDescription: String? {
        switch self {
        case .applicationSupportUnavailable:
            "履歴の保存先を取得できませんでした"
        case .createDirectoryFailed:
            "履歴フォルダを作成できませんでした"
        case .readFailed:
            "履歴ファイルを読み取れませんでした"
        case .decodeFailed:
            "履歴ファイルの形式が壊れています"
        case .writeFailed:
            "履歴を保存できませんでした"
        case .deleteFailed:
            "履歴を削除できませんでした"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .applicationSupportUnavailable, .createDirectoryFailed:
            "Application Supportフォルダへのアクセス権を確認してください。"
        case .readFailed, .decodeFailed:
            "履歴をすべて削除してから、もう一度お試しください。"
        case .writeFailed:
            "空き容量とApplication Supportフォルダの書き込み権限を確認してください。"
        case .deleteFailed:
            "履歴ファイルを使用しているアプリを閉じてから再試行してください。"
        }
    }
}

public final class JSONHistoryStore {
    public static let defaultMaximumEntryCount = 50

    public let fileURL: URL

    private let maximumEntryCount: Int
    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(
        fileURL: URL,
        maximumEntryCount: Int = JSONHistoryStore.defaultMaximumEntryCount,
        fileManager: FileManager = .default
    ) {
        self.fileURL = fileURL
        self.maximumEntryCount = max(1, maximumEntryCount)
        self.fileManager = fileManager

        encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    public convenience init(
        filePath: String,
        maximumEntryCount: Int = JSONHistoryStore.defaultMaximumEntryCount
    ) {
        self.init(
            fileURL: URL(fileURLWithPath: filePath),
            maximumEntryCount: maximumEntryCount
        )
    }

    public static func defaultFileURL(
        fileManager: FileManager = .default
    ) throws(HistoryStoreError) -> URL {
        guard let applicationSupport = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            throw HistoryStoreError.applicationSupportUnavailable
        }

        return applicationSupport
            .appendingPathComponent("AnythingBar", isDirectory: true)
            .appendingPathComponent("history.json", isDirectory: false)
    }

    public func load() throws(HistoryStoreError) -> [HistoryEntry] {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return []
        }

        let data: Data
        do {
            data = try Data(contentsOf: fileURL)
        } catch {
            throw HistoryStoreError.readFailed(error.localizedDescription)
        }

        do {
            return try decoder.decode([HistoryEntry].self, from: data)
        } catch {
            throw HistoryStoreError.decodeFailed(error.localizedDescription)
        }
    }

    @discardableResult
    public func record(
        content: CapturedContent,
        action: ActionItem,
        executedAt: Date = Date(),
        policy: HistoryPolicy
    ) throws(HistoryStoreError) -> HistorySaveResult {
        guard policy.isEnabled else {
            return .skippedDisabled
        }

        if content.type.kind == .email, !policy.savesEmailAddresses {
            return .skippedEmail
        }

        var entries = try load()
        if entries.first?.normalizedValue == content.normalizedValue {
            return .skippedDuplicate
        }

        let entry = HistoryEntry(
            rawValue: content.rawValue,
            normalizedValue: content.normalizedValue,
            contentKind: content.type.kind,
            capturedAt: content.capturedAt,
            actionID: action.actionID,
            actionTitle: action.title,
            executedAt: executedAt
        )
        entries.insert(entry, at: 0)
        entries = Array(entries.prefix(maximumEntryCount))
        try save(entries)
        return .saved
    }

    public func clear() throws(HistoryStoreError) {
        guard fileManager.fileExists(atPath: fileURL.path) else { return }

        do {
            try fileManager.removeItem(at: fileURL)
        } catch {
            throw HistoryStoreError.deleteFailed(error.localizedDescription)
        }
    }

    private func save(_ entries: [HistoryEntry]) throws(HistoryStoreError) {
        let directoryURL = fileURL.deletingLastPathComponent()

        do {
            try fileManager.createDirectory(
                at: directoryURL,
                withIntermediateDirectories: true
            )
        } catch {
            throw HistoryStoreError.createDirectoryFailed(error.localizedDescription)
        }

        let data: Data
        do {
            data = try encoder.encode(entries)
        } catch {
            throw HistoryStoreError.writeFailed(error.localizedDescription)
        }

        do {
            try data.write(to: fileURL, options: .atomic)
        } catch {
            throw HistoryStoreError.writeFailed(error.localizedDescription)
        }
    }
}
