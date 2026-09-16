import Foundation

struct DrillSettings: Codable, Equatable, Sendable {
    var questionCount: Int
    var minOperand: Int
    var maxOperand: Int
    var multiplicationMax: Int

    init(
        questionCount: Int = 20,
        minOperand: Int = 1,
        maxOperand: Int = 20,
        multiplicationMax: Int = 12
    ) {
        self.questionCount = questionCount
        self.minOperand = minOperand
        self.maxOperand = maxOperand
        self.multiplicationMax = multiplicationMax
    }

    static let `default` = DrillSettings()
}
