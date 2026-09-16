import Foundation

struct DrillAttempt: Identifiable, Equatable, Sendable {
    let id: UUID
    let question: DrillQuestion
    let submittedAnswer: Int?
    let isCorrect: Bool
    let elapsed: Duration

    init(
        id: UUID = UUID(),
        question: DrillQuestion,
        submittedAnswer: Int?,
        isCorrect: Bool,
        elapsed: Duration
    ) {
        self.id = id
        self.question = question
        self.submittedAnswer = submittedAnswer
        self.isCorrect = isCorrect
        self.elapsed = elapsed
    }
}

struct DrillSession: Identifiable, Equatable, Sendable {
    let id: UUID
    let kind: DrillKind
    let questions: [DrillQuestion]
    var attempts: [DrillAttempt]
    let startedAt: Date
    var finishedAt: Date?

    init(
        id: UUID = UUID(),
        kind: DrillKind,
        questions: [DrillQuestion],
        attempts: [DrillAttempt] = [],
        startedAt: Date = .now,
        finishedAt: Date? = nil
    ) {
        self.id = id
        self.kind = kind
        self.questions = questions
        self.attempts = attempts
        self.startedAt = startedAt
        self.finishedAt = finishedAt
    }

    var currentIndex: Int { attempts.count }

    var isFinished: Bool { finishedAt != nil || currentIndex >= questions.count }

    var currentQuestion: DrillQuestion? {
        guard currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }

    var correctCount: Int { attempts.filter(\.isCorrect).count }

    var accuracy: Double {
        guard !attempts.isEmpty else { return 0 }
        return Double(correctCount) / Double(attempts.count)
    }
}

struct DrillRecord: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let kind: DrillKind
    let startedAt: Date
    let finishedAt: Date
    let questionCount: Int
    let correctCount: Int
    let durationSeconds: Double

    var accuracy: Double {
        guard questionCount > 0 else { return 0 }
        return Double(correctCount) / Double(questionCount)
    }

    init(session: DrillSession) {
        self.id = session.id
        self.kind = session.kind
        self.startedAt = session.startedAt
        self.finishedAt = session.finishedAt ?? .now
        self.questionCount = session.questions.count
        self.correctCount = session.correctCount
        self.durationSeconds = finishedAt.timeIntervalSince(startedAt)
    }
}
