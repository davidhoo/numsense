import SwiftUI

struct SummaryView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        NavigationStack {
            List {
                if let session = appModel.lastFinished {
                    Section("Score") {
                        LabeledContent("First listen") {
                            Text("\(session.firstListenCorrectSlots) / \(max(session.slotCount, 1))")
                                .monospacedDigit()
                        }
                        LabeledContent("Items", value: "\(session.itemAttempts.count)")
                        LabeledContent("Source", value: session.source.capitalized)
                    }

                    Section("By scenario") {
                        let groups = Dictionary(grouping: session.itemAttempts, by: \.scenario)
                        ForEach(groups.keys.sorted(), id: \.self) { key in
                            let items = groups[key] ?? []
                            let slots = items.flatMap(\.slotAttempts)
                            let ok = slots.filter(\.firstTapCorrect).count
                            LabeledContent(Scenario(rawValue: key)?.title ?? key) {
                                Text("\(ok)/\(slots.count)")
                                    .monospacedDigit()
                            }
                        }
                    }

                    if !appModel.log.missedItemIDs().isEmpty {
                        Section {
                            Button("Review missed") {
                                appModel.startReview()
                            }
                        }
                    }
                } else {
                    Text("No items in this session.")
                }
            }
            .navigationTitle("Session")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { appModel.dismissSummary() }
                }
            }
        }
    }
}
