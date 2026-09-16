import Foundation

enum Scenario: String, Codable, CaseIterable, Identifiable, Hashable {
    case time, date, money, room, travel, phone, address, measures, mixed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .time: "Time"
        case .date: "Date"
        case .money: "Money"
        case .room: "Room"
        case .travel: "Travel"
        case .phone: "Phone"
        case .address: "Address"
        case .measures: "Measures"
        case .mixed: "Mixed"
        }
    }

    var systemImage: String {
        switch self {
        case .time: "clock"
        case .date: "calendar"
        case .money: "dollarsign"
        case .room: "door.left.hand.closed"
        case .travel: "airplane"
        case .phone: "phone"
        case .address: "house"
        case .measures: "scalemass"
        case .mixed: "square.grid.2x2"
        }
    }
}

struct CatalogFile: Codable {
    var version: Int
    var items: [CatalogItem]
}

struct CatalogItem: Codable, Identifiable, Hashable {
    var id: String
    var scenario: Scenario
    var spokenText: String
    var audioFile: String
    var variantTags: [String]
    var trapTags: [String]
    var slots: [CatalogSlot]
}

struct CatalogSlot: Codable, Identifiable, Hashable {
    var id: String
    var role: String
    var visual: String
    var value: SlotValue
    var distractors: [SlotValue]
}

struct SlotValue: Codable, Hashable {
    var type: String
    var hour: Int?
    var minute: Int?
    var ampm: String?
    var minutes: Int?
    var month: Int?
    var day: Int?
    var weekday: String?
    var cents: Int?
    var text: String?
    var letter: String?
    var number: Int?
    var amount: Double?
    var unit: String?
    var percent: Int?
    var degrees: Int?
    var gallons: Double?
    var miles: Double?
    var mph: Int?
    var psi: Int?
}

enum ClockStyle: String, Codable, CaseIterable {
    case digital
    case analog
}

enum TimeHourFormat: String, Codable, CaseIterable {
    case twelve
    case twentyFour
}

struct AppSettings: Codable, Equatable {
    var clockStyle: ClockStyle
    var timeFormat: TimeHourFormat
    var sessionLength: Int
    var scenarioFilter: Scenario?
    var playInSilentMode: Bool

    static let `default` = AppSettings(
        clockStyle: .digital,
        timeFormat: .twelve,
        sessionLength: 12,
        scenarioFilter: nil,
        playInSilentMode: true
    )
}

extension CatalogSlot {
    func optionsShuffled(using rng: inout some RandomNumberGenerator) -> [SlotValue] {
        ([value] + distractors).shuffled(using: &rng)
    }

    func prompt(slotIndex: Int, slotCount: Int) -> String {
        let detail: String
        switch role {
        case "clock":
            detail = "What time did you hear?"
        case "duration":
            detail = "How long did they say? (minutes or hours)"
        case "date":
            detail = "What date did you hear?"
        case "weekday":
            detail = "What day of the week did you hear?"
        case "amount":
            detail = "What dollar amount did you hear?"
        case "fuelPrice":
            detail = "What was the price per gallon?"
        case "room":
            detail = "What room number did you hear?"
        case "floor":
            detail = "What floor did they say?"
        case "seat":
            detail = "What seat did you hear?"
        case "apt":
            detail = "What apartment / suite did you hear?"
        case "parking":
            detail = "What parking space did you hear?"
        case "parkingLevel":
            detail = "What parking level did you hear?"
        case "gate":
            detail = "Which gate did you hear?"
        case "flight":
            detail = "What flight number did you hear?"
        case "terminal":
            detail = "Which terminal did you hear?"
        case "carousel":
            detail = "Which baggage carousel did you hear?"
        case "bus":
            detail = "Which bus / train number did you hear?"
        case "phone":
            detail = "Which phone digits did you hear for this group?"
        case "code":
            detail = "What code / last four did you hear?"
        case "extension":
            detail = "What extension did you hear?"
        case "address":
            detail = "What street / house number did you hear?"
        case "zip":
            detail = "What ZIP code did you hear?"
        case "count", "window":
            detail = "What number did you hear?"
        case "aisle":
            detail = "Which aisle did you hear?"
        case "weight":
            detail = "What weight did you hear?"
        case "fuel":
            detail = "How many gallons did you hear?"
        case "distance":
            detail = "What distance did you hear?"
        case "speed":
            detail = "What speed did you hear?"
        case "pressure":
            detail = "What tire pressure (PSI) did you hear?"
        case "temperature":
            detail = "What temperature did you hear?"
        case "percent":
            detail = "What percent did you hear?"
        case "highway":
            detail = "Which highway did you hear?"
        case "exit":
            detail = "Which exit did you hear?"
        case "volume":
            detail = "What quantity did you hear?"
        default:
            detail = "Which value did you hear?"
        }
        if slotCount > 1 {
            return "This clip had \(slotCount) numbers. (\(slotIndex + 1) of \(slotCount)) \(detail)"
        }
        return detail
    }
}
