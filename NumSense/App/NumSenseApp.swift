import SwiftUI

@main
struct NumSenseApp: App {
    @State private var appModel: AppModel
    private var screenshotMode: String?

    init() {
        let model = AppModel()
        #if DEBUG
        let mode = ScreenshotHelper.configure(model: model)
        self.screenshotMode = mode
        #else
        self.screenshotMode = nil
        #endif
        _appModel = State(initialValue: model)
    }

    var body: some Scene {
        WindowGroup {
            RootView(screenshotMode: screenshotMode)
                .environment(appModel)
        }
    }
}

struct RootView: View {
    @Environment(AppModel.self) private var appModel
    var screenshotMode: String? = nil

    var body: some View {
        Group {
            #if DEBUG
            if screenshotMode == "stats" {
                NavigationStack {
                    StatsView()
                }
            } else {
                rootContent
            }
            #else
            rootContent
            #endif
        }
    }

    @ViewBuilder
    private var rootContent: some View {
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
