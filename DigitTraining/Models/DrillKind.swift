import Foundation

enum DrillKind: String, CaseIterable, Identifiable, Codable {
    case addition
    case subtraction
    case multiplication
    case mixed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .addition: "加法"
        case .subtraction: "减法"
        case .multiplication: "乘法"
        case .mixed: "混合运算"
        }
    }

    var subtitle: String {
        switch self {
        case .addition: "两数相加，练反应"
        case .subtraction: "两数相减，结果不为负"
        case .multiplication: "口诀范围内的乘法"
        case .mixed: "加、减、乘随机出题"
        }
    }

    var systemImage: String {
        switch self {
        case .addition: "plus.circle.fill"
        case .subtraction: "minus.circle.fill"
        case .multiplication: "xmark.circle.fill"
        case .mixed: "shuffle.circle.fill"
        }
    }
}
