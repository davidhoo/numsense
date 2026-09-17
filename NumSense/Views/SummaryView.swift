import SwiftUI
import Charts

struct SummaryView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        NavigationStack {
            List {
                if let session = appModel.lastFinished {
                    Section("Score & Speed") {
                        LabeledContent("First listen") {
                            Text("\(session.firstListenCorrectSlots) / \(max(session.slotCount, 1))")
                                .monospacedDigit()
                        }
                        if let med = session.medianResponseMs {
                            let sec = Double(med) / 1000.0
                            let tier = session.speedTier
                            LabeledContent("Median Speed") {
                                HStack(spacing: 6) {
                                    Image(systemName: tier.systemImage)
                                        .foregroundStyle(tier.color)
                                    Text(String(format: "%.2fs", sec))
                                        .monospacedDigit()
                                        .fontWeight(.semibold)
                                    Text(tier.title)
                                        .font(.caption.weight(.medium))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(tier.color.opacity(0.15))
                                        .foregroundStyle(tier.color)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        LabeledContent("Items", value: "\(session.itemAttempts.count)")
                        LabeledContent("Source", value: session.source.capitalized)
                    }

                    let slots = session.allSlotAttemptsFlat
                    if !slots.isEmpty {
                        Section("Pace & Rhythm") {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Label("Correct", systemImage: "circle.fill")
                                        .font(.caption2)
                                        .foregroundStyle(.green)
                                    Spacer()
                                    Label("Missed", systemImage: "circle.fill")
                                        .font(.caption2)
                                        .foregroundStyle(.red)
                                    Spacer()
                                    Label("Median", systemImage: "minus")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }

                                Chart {
                                    ForEach(Array(slots.enumerated()), id: \.offset) { idx, slot in
                                        let sec = Double(slot.responseMs) / 1000.0
                                        BarMark(
                                            x: .value("Question", idx + 1),
                                            y: .value("Time", sec)
                                        )
                                        .foregroundStyle(slot.firstTapCorrect ? Color.green.gradient : Color.red.gradient)
                                        .cornerRadius(4)
                                    }

                                    if let med = session.medianResponseMs {
                                        RuleMark(y: .value("Median", Double(med) / 1000.0))
                                            .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                                            .foregroundStyle(Color.secondary)
                                            .annotation(position: .top, alignment: .trailing) {
                                                Text(String(format: "Median %.1fs", Double(med) / 1000.0))
                                                    .font(.caption2)
                                                    .foregroundStyle(.secondary)
                                            }
                                    }
                                }
                                .chartXAxis {
                                    AxisMarks(values: .automatic(desiredCount: min(slots.count, 10)))
                                }
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
                                .frame(height: 140)
                                .padding(.vertical, 4)
                            }
                        }
                    }

                    Section("By scenario") {
                        let groups = Dictionary(grouping: session.itemAttempts, by: \.scenario)
                        ForEach(groups.keys.sorted(), id: \.self) { key in
                            let items = groups[key] ?? []
                            let sList = items.flatMap(\.slotAttempts)
                            let ok = sList.filter(\.firstTapCorrect).count
                            let medMs = AttemptLog.median(of: sList.map(\.responseMs))
                            LabeledContent {
                                HStack(spacing: 8) {
                                    if let medMs {
                                        Text(String(format: "%.1fs", Double(medMs) / 1000.0))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Text("\(ok)/\(sList.count)")
                                        .monospacedDigit()
                                }
                            } label: {
                                Text(Scenario(rawValue: key)?.title ?? key)
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
