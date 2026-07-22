import Foundation

public struct HistoryEntry: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let rawValue: String
    public let normalizedValue: String
    public let contentKind: ContentKind
    public let capturedAt: Date
    public let actionID: ActionID
    public let actionTitle: String
    public let executedAt: Date

    public init(
        id: UUID = UUID(),
        rawValue: String,
        normalizedValue: String,
        contentKind: ContentKind,
        capturedAt: Date,
        actionID: ActionID,
        actionTitle: String,
        executedAt: Date = Date()
    ) {
        self.id = id
        self.rawValue = rawValue
        self.normalizedValue = normalizedValue
        self.contentKind = contentKind
        self.capturedAt = capturedAt
        self.actionID = actionID
        self.actionTitle = actionTitle
        self.executedAt = executedAt
    }
}

public struct HistoryPolicy: Equatable, Sendable {
    public let isEnabled: Bool
    public let savesEmailAddresses: Bool

    public init(isEnabled: Bool, savesEmailAddresses: Bool) {
        self.isEnabled = isEnabled
        self.savesEmailAddresses = savesEmailAddresses
    }
}

public enum HistorySaveResult: Equatable, Sendable {
    case saved
    case skippedDisabled
    case skippedEmail
    case skippedDuplicate
}
