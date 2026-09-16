import Foundation

struct DrillEngine: Sendable {
    var settings: DrillSettings

    init(settings: DrillSettings = .default) {
        self.settings = settings
    }

    func makeSession(kind: DrillKind, rng: inout some RandomNumberGenerator) -> DrillSession {
        let questions = (0..<settings.questionCount).map { _ in
            makeQuestion(kind: resolvedKind(for: kind, rng: &rng), rng: &rng)
        }
        return DrillSession(kind: kind, questions: questions)
    }

    func makeQuestion(kind: DrillKind, rng: inout some RandomNumberGenerator) -> DrillQuestion {
        switch kind {
        case .addition:
            let lhs = int(in: settings.minOperand...settings.maxOperand, rng: &rng)
            let rhs = int(in: settings.minOperand...settings.maxOperand, rng: &rng)
            return DrillQuestion(kind: kind, prompt: "\(lhs) + \(rhs)", answer: lhs + rhs)
        case .subtraction:
            let a = int(in: settings.minOperand...settings.maxOperand, rng: &rng)
            let b = int(in: settings.minOperand...settings.maxOperand, rng: &rng)
            let lhs = max(a, b)
            let rhs = min(a, b)
            return DrillQuestion(kind: kind, prompt: "\(lhs) − \(rhs)", answer: lhs - rhs)
        case .multiplication:
            let lhs = int(in: 1...settings.multiplicationMax, rng: &rng)
            let rhs = int(in: 1...settings.multiplicationMax, rng: &rng)
            return DrillQuestion(kind: kind, prompt: "\(lhs) × \(rhs)", answer: lhs * rhs)
        case .mixed:
            return makeQuestion(kind: resolvedKind(for: .mixed, rng: &rng), rng: &rng)
        }
    }

    private func resolvedKind(for kind: DrillKind, rng: inout some RandomNumberGenerator) -> DrillKind {
        guard kind == .mixed else { return kind }
        return [.addition, .subtraction, .multiplication].randomElement(using: &rng) ?? .addition
    }

    private func int(in range: ClosedRange<Int>, rng: inout some RandomNumberGenerator) -> Int {
        Int.random(in: range, using: &rng)
    }
}
