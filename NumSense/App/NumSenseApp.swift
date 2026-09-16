import SwiftUI

@main
struct NumSenseApp: App {
    @State private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appModel)
        }
    }
}

struct RootView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        Group {
            switch appModel.phase {
            case .idle:
                HomeView()
            case .listen, .waiting, .options, .feedback:
                TrialView()
            case .summary:
                SummaryView()
            }
        }
    }
}
