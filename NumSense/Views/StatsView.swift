import SwiftUI
import Charts

enum TimeRangeOption: String, CaseIterable, Identifiable {
    case seven = "7 Days"
    case thirty = "30 Days"
    case all = "All"

    var id: String { rawValue }

    var days: Int? {
        switch self {
        case .seven: return 7
        case .thirty: return 30
        case .all: return nil
        }
    }
}

struct StatsView: View {
    @Environment(AppModel.self) private var appModel
    @State private var selectedRange: TimeRangeOption = .thirty
    @State private var shareItems: [URL] = []
    @State private var showShare = false
    @State private var exportError: String?

    private var startDate: Date {
        if let days = selectedRange.days {
            return Calendar.current.date(byAdding: .day, value: -days, to: .now) ?? .now
        } else {
            return .distantPast
        }
    }

    var body: some View {
        List {
            Section {
                Picker("Time Range", selection: $selectedRange) {
                    ForEach(TimeRangeOption.allCases) { opt in
                        Text(opt.rawValue).tag(opt)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Overview") {
                LabeledContent("Accuracy", value: percent(appModel.log.accuracy(since: startDate)))

                if let med = appModel.log.medianResponseMs(since: startDate) {
                    let sec = Double(med) / 1000.0
                    let tier = SpeedTier.tier(for: med)
                    LabeledContent("Median Speed") {
                        HStack(spacing: 6) {
                            Image(systemName: tier.systemImage)
                                .foregroundStyle(tier.color)
                            Text(String(format: "%.2fs", sec))
                                .monospacedDigit()
                                .fontWeight(.semibold)
                            Text(tier.title)
                                .font(.caption2.weight(.medium))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(tier.color.opacity(0.15))
                                .foregroundStyle(tier.color)
                                .clipShape(Capsule())
                        }
                    }
                }

                if let correctMed = appModel.log.medianResponseMs(since: startDate, correctOnly: true) {
                    LabeledContent("Correct-only Speed") {
                        Text(String(format: "%.2fs", Double(correctMed) / 1000.0))
                            .monospacedDigit()
                    }
                }

                LabeledContent("Streak", value: "\(appModel.log.completionStreak()) days")
                LabeledContent("Sessions", value: "\(sessionsInRange.count)")
            }

            // Chart 1: Daily Speed Trend
            let trends = appModel.log.dailySpeedTrend(since: startDate)
            if !trends.isEmpty {
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Daily Response Speed")
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Label("Target: 1.5s", systemImage: "bolt.fill")
                                .font(.caption2)
                                .foregroundStyle(.green)
                        }

                        Chart {
                            ForEach(trends) { item in
                                AreaMark(
                                    x: .value("Date", item.date, unit: .day),
                                    y: .value("Speed", item.medianSeconds)
                                )
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.blue.opacity(0.25), Color.clear],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )

                                LineMark(
                                    x: .value("Date", item.date, unit: .day),
                                    y: .value("Speed", item.medianSeconds)
                                )
                                .foregroundStyle(Color.blue)
                                .interpolationMethod(.catmullRom)

                                PointMark(
                                    x: .value("Date", item.date, unit: .day),
                                    y: .value("Speed", item.medianSeconds)
                                )
                                .foregroundStyle(Color.blue)
                                .symbolSize(28)
                            }

                            RuleMark(y: .value("Reflex Target", 1.5))
                                .lineStyle(StrokeStyle(lineWidth: 1.2, dash: [4, 4]))
                                .foregroundStyle(Color.green)
                        }
                        .chartYScale(domain: 0 ... max(3.5, (trends.map(\.medianSeconds).max() ?? 2.5) + 0.6))
                        .chartYAxis {
                            AxisMarks { value in
                                AxisGridLine()
                                AxisValueLabel {
                                    if let v = value.as(Double.self) {
                                        Text(String(format: "%.1fs", v))
                                            .font(.caption2)
                                    }
                                }
                            }
                        }
                        .chartXAxis {
                            AxisMarks(values: .automatic(desiredCount: min(trends.count, 6))) { _ in
                                AxisGridLine()
                                AxisValueLabel(format: .dateTime.month(.defaultDigits).day())
                            }
                        }
                        .frame(height: 160)

                        Text("Daily median response time. Lower time reflects intuitive number sense without mental translation.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Fluency Trend")
                }
            }

            // Chart 2: Fluency Quadrants
            let scenarioStats = appModel.log.scenarioSpeedAndAccuracy(since: startDate)
            if !scenarioStats.isEmpty {
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Grid(horizontalSpacing: 8, verticalSpacing: 4) {
                            GridRow {
                                Text("🎯 Reflex (<1.8s, >85%)")
                                    .font(.caption2)
                                    .foregroundStyle(.green)
                                Text("🧠 Translation (>1.8s, >85%)")
                                    .font(.caption2)
                                    .foregroundStyle(.orange)
                            }
                            GridRow {
                                Text("⚡ Impulse (<1.8s, <85%)")
                                    .font(.caption2)
                                    .foregroundStyle(.yellow)
                                Text("🌪️ Overload (>1.8s, <85%)")
                                    .font(.caption2)
                                    .foregroundStyle(.red)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))

                        Chart {
                            RuleMark(x: .value("Speed Split", 1.8))
                                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                                .foregroundStyle(Color.secondary.opacity(0.4))

                            RuleMark(y: .value("Accuracy Split", 0.85))
                                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                                .foregroundStyle(Color.secondary.opacity(0.4))

                            ForEach(scenarioStats) { item in
                                PointMark(
                                    x: .value("Response Time", item.medianSeconds),
                                    y: .value("Accuracy", item.accuracy)
                                )
                                .foregroundStyle(item.tier.color)
                                .symbolSize(80)
                                .annotation(position: .top) {
                                    HStack(spacing: 2) {
                                        Image(systemName: item.scenario.systemImage)
                                            .font(.system(size: 8))
                                        Text(item.scenario.title)
                                            .font(.system(size: 9, weight: .semibold))
                                    }
                                    .foregroundStyle(.primary)
                                }
                            }
                        }
                        .chartXScale(domain: 0.4 ... max(3.2, (scenarioStats.map(\.medianSeconds).max() ?? 2.5) + 0.5))
                        .chartYScale(domain: 0.35 ... 1.05)
                        .chartXAxis {
                            AxisMarks { value in
                                AxisGridLine()
                                AxisValueLabel {
                                    if let v = value.as(Double.self) {
                                        Text(String(format: "%.1fs", v))
                                            .font(.caption2)
                                    }
                                }
                            }
                        }
                        .chartYAxis {
                            AxisMarks { value in
                                AxisGridLine()
                                AxisValueLabel {
                                    if let v = value.as(Double.self) {
                                        Text("\(Int(v * 100))%")
                                            .font(.caption2)
                                    }
                                }
                            }
                        }
                        .frame(height: 190)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Fluency Quadrants")
                }

                // Chart 3: Speed by Scenario
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Chart {
                            ForEach(scenarioStats.sorted(by: { $0.medianMs < $1.medianMs })) { item in
                                BarMark(
                                    x: .value("Time", item.medianSeconds),
                                    y: .value("Scenario", item.scenario.title)
                                )
                                .foregroundStyle(item.tier.color.gradient)
                                .annotation(position: .trailing) {
                                    Text(String(format: "%.1fs (%d%%)", item.medianSeconds, Int(item.accuracy * 100)))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            RuleMark(x: .value("Goal", 1.5))
                                .lineStyle(StrokeStyle(lineWidth: 1.2, dash: [3, 3]))
                                .foregroundStyle(Color.green)
                        }
                        .chartXAxis {
                            AxisMarks { value in
                                AxisGridLine()
                                AxisValueLabel {
                                    if let v = value.as(Double.self) {
                                        Text(String(format: "%.1fs", v))
                                            .font(.caption2)
                                    }
                                }
                            }
                        }
                        .frame(height: CGFloat(max(140, scenarioStats.count * 32)))
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Speed by Scenario")
                }
            }

            // Chart 4: Multi-Step Working Memory Decay
            let slotStats = appModel.log.slotIndexSpeedAndAccuracy(since: startDate)
            if slotStats.count > 1 {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Chart {
                            ForEach(slotStats) { item in
                                BarMark(
                                    x: .value("Step", "Slot \(item.slotIndex + 1)"),
                                    y: .value("Time", item.medianSeconds)
                                )
                                .foregroundStyle(Color.indigo.gradient)
                                .annotation(position: .top) {
                                    Text(String(format: "%.1fs  ·  %d%%", item.medianSeconds, Int(item.accuracy * 100)))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .chartYScale(domain: 0 ... max(3.0, (slotStats.map(\.medianSeconds).max() ?? 2.0) + 0.6))
                        .chartYAxis {
                            AxisMarks { value in
                                AxisGridLine()
                                AxisValueLabel {
                                    if let v = value.as(Double.self) {
                                        Text(String(format: "%.1fs", v))
                                            .font(.caption2)
                                    }
                                }
                            }
                        }
                        .frame(height: 130)

                        Text("Compares reaction time across sequential questions. An upward climb indicates working memory decay.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Working Memory by Slot")
                }
            }

            Section("Confusion") {
                let pairs = appModel.log.confusionPairs(since: startDate, minimum: 2)
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
                let historySessions = Array(sessionsInRange.prefix(30))
                if historySessions.isEmpty {
                    Text("No sessions in this time range.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(historySessions) { session in
                        NavigationLink {
                            SessionDetailView(session: session)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(session.startedAt.formatted(date: .abbreviated, time: .shortened))
                                    Spacer()
                                    if let med = session.medianResponseMs {
                                        Text(String(format: "%.1fs", Double(med) / 1000.0))
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(session.speedTier.color)
                                    }
                                }
                                Text("\(session.firstListenCorrectSlots)/\(max(session.slotCount, 1))  ·  \(session.source)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
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

    private var sessionsInRange: [SessionRecord] {
        appModel.log.sessions.filter { $0.startedAt >= startDate }
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
