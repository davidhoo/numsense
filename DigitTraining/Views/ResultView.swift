import SwiftUI

struct ResultView: View {
    let session: DrillSession
    @Environment(AppModel.self) private var appModel

    var body: some View {
        VStack(spacing: 20) {
            Text("本轮完成")
                .font(.title2.weight(.semibold))

            Text("\(session.correctCount) / \(session.questions.count)")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .monospacedDigit()

            Text("正确率 \(session.accuracy.formatted(.percent.precision(.fractionLength(0))))")
                .foregroundStyle(.secondary)

            List(session.attempts) { attempt in
                HStack {
                    Image(systemName: attempt.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(attempt.isCorrect ? .green : .red)
                    Text(attempt.question.prompt)
                        .monospacedDigit()
                    Spacer()
                    Text(resultText(attempt))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }

            Button("返回首页") {
                appModel.endSession()
            }
            .buttonStyle(.borderedProminent)
            .padding(.bottom)
        }
        .padding(.top)
    }

    private func resultText(_ attempt: DrillAttempt) -> String {
        if attempt.isCorrect {
            return "\(attempt.question.answer)"
        }
        let submitted = attempt.submittedAnswer.map(String.init) ?? "—"
        return "\(submitted) → \(attempt.question.answer)"
    }
}
