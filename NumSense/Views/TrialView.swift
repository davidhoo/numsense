import SwiftUI

struct TrialView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Text(appModel.progressLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    listenChrome

                    if appModel.phase == .feedback, appModel.lastAnswerWasWrong {
                        spokenTranscript
                    }

                    if appModel.phase == .options || appModel.phase == .feedback {
                        questionChrome
                        optionGrid
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
            }
            .navigationTitle(appModel.currentItem?.scenario.title ?? "Listen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("End") { appModel.endSessionEarly() }
                }
            }
        }
    }

    @ViewBuilder
    private var listenChrome: some View {
        VStack(spacing: 8) {
            Button {
                appModel.replayFromEar()
            } label: {
                Image(systemName: appModel.phase == .listen ? "speaker.wave.2.fill" : "ear")
                    .font(.largeTitle)
                    .symbolEffect(.variableColor.iterative, isActive: appModel.phase == .listen)
                    .frame(width: 56, height: 56)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Replay audio")
            .disabled(appModel.currentItem == nil)

            Text(statusText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    private var spokenTranscript: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("What was said")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text("“\(appModel.currentItem?.spokenText ?? "")”")
                .font(.body)
                .italic()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
        .accessibilityLabel("Spoken sentence: \(appModel.currentItem?.spokenText ?? "")")
    }

    private var statusText: String {
        switch appModel.phase {
        case .listen: "Listen — tap the speaker to hear it again"
        case .waiting: "Hold it…"
        case .options: "Choose — tap the ear to replay"
        case .feedback:
            appModel.lastAnswerWasWrong ? "Compare with the sentence" : " "
        default: ""
        }
    }

    @ViewBuilder
    private var questionChrome: some View {
        let question = appModel.currentQuestion
        VStack(spacing: 10) {
            if let item = appModel.currentItem, item.slots.count > 1 {
                SlotStepStrip(slots: item.slots, currentIndex: appModel.slotIndex)
            }
            Text(question.title)
                .font(.title2.weight(.bold))
            Text(question.cue)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(question.title). \(question.cue)")
    }

    private var optionGrid: some View {
        let options = appModel.live?.options ?? []
        let question = appModel.currentQuestion
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(Array(options.enumerated()), id: \.offset) { _, option in
                Button {
                    appModel.choose(option)
                } label: {
                    SlotOptionCard(
                        value: option,
                        settings: appModel.settings,
                        question: question,
                        isSelected: appModel.live?.chosen == option,
                        verdict: appModel.verdict(for: option)
                    )
                    .frame(minHeight: 140)
                }
                .buttonStyle(.plain)
                .disabled(appModel.phase != .options)
            }
        }
    }
}

struct SlotStepStrip: View {
    let slots: [CatalogSlot]
    let currentIndex: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(slots.enumerated()), id: \.offset) { index, _ in
                let question = SlotQuestion.resolve(slots: slots, index: index)
                let selected = index == currentIndex
                Text(question.stripTitle)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        selected ? Color.accentColor.opacity(0.18) : Color.secondary.opacity(0.12),
                        in: Capsule()
                    )
                    .overlay {
                        Capsule()
                            .strokeBorder(selected ? Color.accentColor : .clear, lineWidth: 1.5)
                    }
                    .foregroundStyle(selected ? Color.primary : Color.secondary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Question \(currentIndex + 1) of \(slots.count), \(SlotQuestion.resolve(slots: slots, index: currentIndex).stripTitle)")
    }
}
