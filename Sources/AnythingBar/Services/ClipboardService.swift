import AnythingBarCore
import AppKit

@MainActor
protocol PasteboardReading {
    var hasItems: Bool { get }
    func readString() -> String?
}

@MainActor
struct SystemPasteboardReader: PasteboardReading {
    private let pasteboard: NSPasteboard

    init(pasteboard: NSPasteboard = .general) {
        self.pasteboard = pasteboard
    }

    var hasItems: Bool {
        !(pasteboard.pasteboardItems?.isEmpty ?? true)
    }

    func readString() -> String? {
        pasteboard.string(forType: .string)
    }
}

@MainActor
final class ClipboardService<Reader: PasteboardReading> {
    private let reader: Reader

    init(reader: Reader) {
        self.reader = reader
    }

    func readText() throws(ClipboardReadError) -> ClipboardPayload {
        guard let rawValue = reader.readString() else {
            throw reader.hasItems ? ClipboardReadError.nonText : ClipboardReadError.empty
        }

        let normalizedValue = ContentNormalizer.normalize(rawValue)
        guard !normalizedValue.isEmpty else {
            throw ClipboardReadError.empty
        }

        return ClipboardPayload(
            rawValue: rawValue,
            normalizedValue: normalizedValue
        )
    }
}

extension ClipboardService where Reader == SystemPasteboardReader {
    convenience init() {
        self.init(reader: SystemPasteboardReader())
    }
}
