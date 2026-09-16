import Foundation
import Testing
@testable import DigitTraining

struct DrillEngineTests {
    @Test func additionProducesMatchingSum() {
        let engine = DrillEngine(settings: DrillSettings(minOperand: 3, maxOperand: 3))
        var rng = SeededGenerator(seed: 1)
        let question = engine.makeQuestion(kind: .addition, rng: &rng)
        #expect(question.prompt == "3 + 3")
        #expect(question.answer == 6)
    }

    @Test func subtractionNeverGoesNegative() {
        let engine = DrillEngine(settings: DrillSettings(minOperand: 1, maxOperand: 9))
        var rng = SeededGenerator(seed: 42)
        for _ in 0..<40 {
            let question = engine.makeQuestion(kind: .subtraction, rng: &rng)
            #expect(question.answer >= 0)
        }
    }

    @Test func sessionHasConfiguredQuestionCount() {
        let engine = DrillEngine(settings: DrillSettings(questionCount: 7))
        var rng = SeededGenerator(seed: 9)
        let session = engine.makeSession(kind: .mixed, rng: &rng)
        #expect(session.questions.count == 7)
        #expect(session.kind == .mixed)
    }
}

private struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
