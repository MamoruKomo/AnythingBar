import AnythingBarCore
import Combine

struct ActionBarStatus: Equatable {
    let text: String
    let isError: Bool
}

@MainActor
final class ActionBarViewModel: ObservableObject {
    let content: CapturedContent?
    let actions: [ActionItem]

    @Published var query = "" {
        didSet {
            selectedIndex = 0
        }
    }
    @Published var selectedIndex = 0
    @Published var status: ActionBarStatus?

    var onExecute: (ActionItem) -> Void = { _ in }
    var onDismiss: () -> Void = {}
    var onCopyCurrentContent: () -> Void = {}

    var filteredActions: [ActionItem] {
        actions.filter { $0.matches(query: query) }
    }

    init(
        content: CapturedContent?,
        actions: [ActionItem],
        status: ActionBarStatus? = nil
    ) {
        self.content = content
        self.actions = actions
        self.status = status
    }

    func moveSelection(by offset: Int) {
        let count = filteredActions.count
        guard count > 0 else {
            selectedIndex = 0
            return
        }

        selectedIndex = (selectedIndex + offset + count) % count
    }

    func select(index: Int) {
        guard filteredActions.indices.contains(index) else { return }
        selectedIndex = index
    }

    func executeSelected() {
        guard filteredActions.indices.contains(selectedIndex) else { return }
        onExecute(filteredActions[selectedIndex])
    }

    func setStatus(_ text: String, isError: Bool) {
        status = ActionBarStatus(text: text, isError: isError)
    }
}
