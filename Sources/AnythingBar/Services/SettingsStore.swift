import Combine
import Foundation

@MainActor
final class SettingsStore: ObservableObject {
    private enum Key {
        static let historyEnabled = "historyEnabled"
        static let emailHistoryEnabled = "emailHistoryEnabled"
    }

    @Published var historyEnabled: Bool {
        didSet { defaults.set(historyEnabled, forKey: Key.historyEnabled) }
    }

    @Published var emailHistoryEnabled: Bool {
        didSet { defaults.set(emailHistoryEnabled, forKey: Key.emailHistoryEnabled) }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        if defaults.object(forKey: Key.historyEnabled) == nil {
            historyEnabled = true
        } else {
            historyEnabled = defaults.bool(forKey: Key.historyEnabled)
        }

        if defaults.object(forKey: Key.emailHistoryEnabled) == nil {
            emailHistoryEnabled = false
        } else {
            emailHistoryEnabled = defaults.bool(forKey: Key.emailHistoryEnabled)
        }
    }
}
