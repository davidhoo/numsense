import SwiftUI

struct DrillView: View {
    let kind: DrillKind

    @Environment(AppModel.self) private var appModel
    @State private var answerText = ""
    @FocusState private var answerFocused: Bool

    var body: some View {
        Group {
            if let session = appModel.activeSession, session.kind == kind {
                if session.isFinished {
                    ResultView(session: session)
                } else if let question = session.currentQuestion {
                    questionPage(session: session, question: question)
                }
            } else {
                Color.clear
                    .onAppear { startIfNeeded() }
            }
        }
        .navigationTitle(kind.title)
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            if appModel.activeSession?.isFinished == true {
                appModel.endSession()
            }
        }
    }

    private func questionPage(session: DrillSession, question: DrillQuestion) -> some View {
        VStack(spacing: 28) {
            Text("第 \(session.currentIndex + 1) / \(session.questions.count) 题")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(question.prompt)
                .font(.system(size: 56, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            TextField("答案", text: $answerText)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
                .font(.title)
                .multilineTextAlignment(.center)
                .focused($answerFocused)
                .onSubmit(submit)

            Button("提交", action: submit)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(answerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            Spacer()
        }
        .padding()
        .onAppear { answerFocused = true }
    }

    private func startIfNeeded() {
        if appModel.activeSession?.kind != kind || appModel.activeSession?.isFinished == true {
            appModel.start(kind: kind)
            answerText = ""
        }
    }

    private func submit() {
        appModel.submit(answerText)
        answerText = ""
        answerFocused = true
    }
}
