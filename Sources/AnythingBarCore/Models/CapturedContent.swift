import Foundation

public struct CapturedContent: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let rawValue: String
    public let normalizedValue: String
    public let type: ContentType
    public let capturedAt: Date

    public init(
        id: UUID = UUID(),
        rawValue: String,
        normalizedValue: String,
        type: ContentType,
        capturedAt: Date = Date()
    ) {
        self.id = id
        self.rawValue = rawValue
        self.normalizedValue = normalizedValue
        self.type = type
        self.capturedAt = capturedAt
    }
}
