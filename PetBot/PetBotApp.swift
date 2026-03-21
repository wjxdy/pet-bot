import SwiftUI

@main
struct PetBotApp: App {
    @StateObject private var viewModel = PetBotViewModel()
    
    var body: some Scene {
        WindowGroup {
            PetView(viewModel: viewModel)
                .frame(minWidth: 300, minHeight: 400)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}

class PetBotViewModel: ObservableObject {
    @Published var currentAgent: Agent = .shennong
    @Published var petState: PetState = .idle
    
    enum PetState {
        case idle, listening, thinking, speaking
    }
}

enum Agent: String, CaseIterable {
    case shennong = "神农"
    case main = "主助手"
    case search = "搜索专家"
    case claude = "Claude"
    
    var icon: String {
        switch self {
        case .shennong: return "🌿"
        case .main: return "🤖"
        case .search: return "🔍"
        case .claude: return "🧠"
        }
    }
}
