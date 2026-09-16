import SwiftUI

struct StatsView: View {
    @Environment(AppModel.self) private var appModel
    @State private var shareItems: [URL] = []
    @State private var showShare = false
    @State private var exportError: String?

    var body: some View {
        List {
            Section("Overview") {
                LabeledContent("7-day", value: percent(appModel.sevenDayAccuracy))
                LabeledContent("30-day", value: percent(appModel.log.accuracy(since: daysAgo(30))))
                LabeledContent("Streak", value: "\(appModel.log.completionStreak()) days")
                LabeledContent("Sessions", value: "\(appModel.log.sessions.count)")
            }

            Section("By scenario") {
                let rows = appModel.log.accuracyByScenario(since: daysAgo(30))
                if rows.isEmpty {
                    Text("No practice yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(rows, id: \.0) { scenario, acc, n in
                        LabeledContent(scenario.title) {
                            Text("\(percent(acc))  (\(n))")
                                .monospacedDigit()
                        }
                    }
                }
            }

            Section("Slot index") {
                ForEach(appModel.log.slotIndexAccuracy(since: daysAgo(30)), id: \.0) { idx, acc, n in
                    LabeledContent("Slot \(idx + 1)") {
                        Text("\(percent(acc))  (\(n))")
                            .monospacedDigit()
                    }
                }
            }

            Section("Confusion") {
                let pairs = appModel.log.confusionPairs(since: daysAgo(30), minimum: 2)
                if pairs.isEmpty {
                    Text("Not enough misses yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(pairs, id: \.0) { tag, count in
                        LabeledContent(tag, value: "\(count)")
                    }
                }
            }

            Section("Review") {
                Button("Review missed") {
                    appModel.startReview()
                }
                .disabled(appModel.log.missedItemIDs().isEmpty)
            }

            Section("History") {
                ForEach(Array(appModel.log.sessions.prefix(30))) { session in
                    NavigationLink {
                        SessionDetailView(session: session)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(session.startedAt.formatted(date: .abbreviated, time: .shortened))
                            Text("\(session.firstListenCorrectSlots)/\(max(session.slotCount, 1))  ·  \(session.source)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("Export") {
                Button("Export JSON + CSV") {
                    export()
                }
                if let exportError {
                    Text(exportError)
                        .foregroundStyle(.red)
                        .font(.footnote)
                }
            }
        }
        .navigationTitle("Stats")
        .sheet(isPresented: $showShare) {
            ShareSheet(items: shareItems)
        }
    }

    private func percent(_ value: Double) -> String {
        value.formatted(.percent.precision(.fractionLength(0)))
    }

    private func daysAgo(_ n: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -n, to: .now) ?? .now
    }

    private func export() {
        do {
            let json = try ExportBuilder.jsonData(from: appModel.log)
            let csv = ExportBuilder.csv(from: appModel.log)
            let stamp = ISO8601DateFormatter().string(from: .now).replacingOccurrences(of: ":", with: "")
            let dir = FileManager.default.temporaryDirectory
            let jsonURL = dir.appendingPathComponent("numsense-\(stamp).json")
            let csvURL = dir.appendingPathComponent("numsense-\(stamp)-slots.csv")
            try json.write(to: jsonURL)
            try csv.data(using: .utf8)?.write(to: csvURL)
            shareItems = [jsonURL, csvURL]
            showShare = true
            exportError = nil
        } catch {
            exportError = error.localizedDescription
        }
    }
}

struct SessionDetailView: View {
    let session: SessionRecord

    var body: some View {
        List {
            Section("Session") {
                LabeledContent("Score", value: "\(session.firstListenCorrectSlots)/\(max(session.slotCount, 1))")
                LabeledContent("Completed", value: session.completed ? "Yes" : "No")
            }
            ForEach(session.itemAttempts) { item in
                Section(item.scriptText) {
                    ForEach(item.slotAttempts) { slot in
                        HStack {
                            Image(systemName: slot.firstTapCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(slot.firstTapCorrect ? .green : .red)
                            VStack(alignment: .leading) {
                                Text(slot.role)
                                Text("\(slot.responseMs) ms")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Detail")
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
