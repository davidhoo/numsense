import SwiftUI

struct HomeView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        @Bindable var appModel = appModel
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Hear the number. Hold it as information.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Button {
                            appModel.startPractice()
                        } label: {
                            Text("Start")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(appModel.catalog.items.isEmpty)
                    }
                    .padding(.vertical, 4)
                }

                Section("Scenario") {
                    Picker("Scenario", selection: $appModel.settings.scenarioFilter) {
                        Text("All").tag(Optional<Scenario>.none)
                        ForEach(Scenario.allCases) { scenario in
                            Text(scenario.title).tag(Optional(scenario))
                        }
                    }
                }

                Section("Recent") {
                    LabeledContent("7-day accuracy", value: appModel.sevenDayAccuracy.formatted(.percent.precision(.fractionLength(0))))
                    LabeledContent("Streak", value: "\(appModel.log.completionStreak()) days")
                    if let last = appModel.log.sessions.first {
                        LabeledContent("Last session") {
                            Text("\(last.firstListenCorrectSlots)/\(max(last.slotCount, 1))")
                                .monospacedDigit()
                        }
                    }
                }
            }
            .navigationTitle("NumSense")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink {
                        StatsView()
                    } label: {
                        Image(systemName: "chart.bar")
                    }
                    .accessibilityLabel("Stats")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                }
            }
        }
    }
}
