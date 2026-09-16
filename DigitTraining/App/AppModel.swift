import Foundation
import Observation

@Observable
final class AppModel {
    var settings: DrillSettings
    var records: [DrillRecord]
    var activeSession: DrillSession?

    private let store: SessionStore
    private var engine: DrillEngine
    private var questionStartedAt: Date?

    init(store: SessionStore = SessionStore()) {
        self.store = store
        let settings = DrillSettings.default
        self.settings = settings
        self.engine = DrillEngine(settings: settings)
        self.records = store.load()
    }

    func start(kind: DrillKind) {
        engine.settings = settings
        var rng = SystemRandomNumberGenerator()
        activeSession = engine.makeSession(kind: kind, rng: &rng)
        questionStartedAt = .now
    }

    func submit(_ answerText: String) {
        guard var session = activeSession, let question = session.currentQuestion else { return }
        let submitted = Int(answerText.trimmingCharacters(in: .whitespacesAndNewlines))
        let elapsed = Duration.seconds(Date.now.timeIntervalSince(questionStartedAt ?? .now))
        let attempt = DrillAttempt(
            question: question,
            submittedAnswer: submitted,
            isCorrect: submitted == question.answer,
            elapsed: elapsed
        )
        session.attempts.append(attempt)

        if session.attempts.count >= session.questions.count {
            session.finishedAt = .now
            let record = DrillRecord(session: session)
            store.append(record)
            records.insert(record, at: 0)
        } else {
            questionStartedAt = .now
        }

        activeSession = session
    }

    func endSession() {
        activeSession = nil
        questionStartedAt = nil
    }
}
