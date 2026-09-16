import Foundation

struct DrillQuestion: Identifiable, Equatable, Sendable {
    let id: UUID
    let kind: DrillKind
    let prompt: String
    let answer: Int

    init(id: UUID = UUID(), kind: DrillKind, prompt: String, answer: Int) {
        self.id = id
        self.kind = kind
        self.prompt = prompt
        self.answer = answer
    }
}
