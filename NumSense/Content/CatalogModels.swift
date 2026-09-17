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

struct SlotQuestion: Equatable {
    var title: String
    var cue: String
    var stripTitle: String
    var cardCaption: String
    var emphasizeWeekday: Bool
    var phoneGroupIndex: Int?
    var phoneGroupCount: Int?

    static let generic = SlotQuestion(
        title: "Number",
        cue: "Which number?",
        stripTitle: "No.",
        cardCaption: "NO.",
        emphasizeWeekday: false,
        phoneGroupIndex: nil,
        phoneGroupCount: nil
    )

    static func resolve(slots: [CatalogSlot], index: Int) -> SlotQuestion {
        guard slots.indices.contains(index) else { return .generic }
        let slot = slots[index]
        let indexes = { (role: String) in slots.indices.filter { slots[$0].role == role } }

        if slot.role == "phone" {
            let phone = Array(indexes("phone"))
            let group = phone.firstIndex(of: index) ?? 0
            let names: [(String, String, String)]
            switch phone.count {
            case 3:
                names = [
                    ("Area", "Which area code?", "AREA"),
                    ("Prefix", "Which prefix?", "PREFIX"),
                    ("Last 4", "Which last four?", "LINE"),
                ]
            case 2:
                names = [
                    ("Prefix", "Which prefix?", "PREFIX"),
                    ("Last 4", "Which last four?", "LINE"),
                ]
            default:
                names = [("Phone", "Which digits?", "NUMBER")]
            }
            let pick = names[min(group, names.count - 1)]
            return SlotQuestion(
                title: pick.0,
                cue: pick.1,
                stripTitle: pick.0,
                cardCaption: pick.2,
                emphasizeWeekday: false,
                phoneGroupIndex: group,
                phoneGroupCount: phone.count
            )
        }

        if slot.role == "clock" {
            let clocks = Array(indexes("clock"))
            if clocks.count >= 2, let group = clocks.firstIndex(of: index) {
                if group == 0 {
                    return make("Opens", "Opens at?", "FROM")
                }
                return make("Closes", "Closes at?", "UNTIL")
            }
            return make("Time", "Which time?", "TIME")
        }

        if slot.role == "amount" {
            return amountQuestion(slots: slots, index: index)
        }

        if slot.role == "weekday" {
            return SlotQuestion(
                title: "Weekday",
                cue: "Which day?",
                stripTitle: "Day",
                cardCaption: "DAY",
                emphasizeWeekday: true,
                phoneGroupIndex: nil,
                phoneGroupCount: nil
            )
        }

        return Self.base[slot.role] ?? make(slot.role.capitalized, "Which \(slot.role)?", slot.role.uppercased())
    }

    private static func amountQuestion(slots: [CatalogSlot], index: Int) -> SlotQuestion {
        let slot = slots[index]
        switch slot.id {
        case "paid": return make("Paid", "How much did they pay?", "PAID")
        case "ch": return make("Change", "How much change?", "CHANGE")
        case "b": return make("Bill", "What was the bill?", "BILL")
        default: break
        }

        let amountIndexes = slots.indices.filter { slots[$0].role == "amount" }
        let group = amountIndexes.firstIndex(of: index) ?? 0
        let hasPercent = slots.contains { $0.role == "percent" }
        if hasPercent {
            return group == 0
                ? make("Bill", "What was the bill?", "BILL")
                : make("Tip", "How much is the tip?", "TIP")
        }
        if amountIndexes.count == 3 {
            let names = [
                ("Bill", "What was the bill?", "BILL"),
                ("Paid", "How much did they pay?", "PAID"),
                ("Change", "How much change?", "CHANGE"),
            ]
            let pick = names[group]
            return make(pick.0, pick.1, pick.2)
        }
        if amountIndexes.count == 2 {
            return group == 0
                ? make("Paid", "How much did they pay?", "PAID")
                : make("Change", "How much change?", "CHANGE")
        }
        return make("Price", "Which amount?", "PRICE")
    }

    private static func make(_ title: String, _ cue: String, _ caption: String, strip: String? = nil) -> SlotQuestion {
        SlotQuestion(
            title: title,
            cue: cue,
            stripTitle: strip ?? title,
            cardCaption: caption,
            emphasizeWeekday: false,
            phoneGroupIndex: nil,
            phoneGroupCount: nil
        )
    }

    private static let base: [String: SlotQuestion] = [
        "duration": make("Duration", "How long?", "WAIT"),
        "date": make("Date", "Which date?", "DATE"),
        "fuelPrice": make("$/gal", "Price per gallon?", "$/GAL", strip: "$/gal"),
        "room": make("Room", "Which room?", "ROOM"),
        "floor": make("Floor", "Which floor?", "FLOOR"),
        "seat": make("Seat", "Which seat?", "SEAT"),
        "apt": make("Apt", "Which apartment?", "APT"),
        "parking": make("Space", "Which space?", "SPACE"),
        "parkingLevel": make("Level", "Which level?", "LEVEL"),
        "gate": make("Gate", "Which gate?", "GATE"),
        "flight": make("Flight", "Which flight?", "FLIGHT"),
        "terminal": make("Terminal", "Which terminal?", "TERM"),
        "carousel": make("Carousel", "Which carousel?", "BAGGAGE"),
        "bus": make("Bus", "Which bus?", "BUS"),
        "code": make("Code", "Which code?", "CODE"),
        "extension": make("Ext", "Which extension?", "EXT"),
        "address": make("House", "Which house number?", "HOUSE"),
        "zip": make("ZIP", "Which ZIP?", "ZIP"),
        "count": make("Party", "Party of how many?", "PARTY"),
        "window": make("Window", "Which window?", "WINDOW"),
        "aisle": make("Aisle", "Which aisle?", "AISLE"),
        "weight": make("Weight", "What weight?", "WEIGHT"),
        "fuel": make("Gallons", "How many gallons?", "PUMP"),
        "distance": make("Miles", "What distance?", "MILES"),
        "speed": make("Speed", "What speed?", "MPH"),
        "pressure": make("PSI", "What tire pressure?", "TIRE"),
        "temperature": make("Temp", "What temperature?", "°F"),
        "percent": make("Percent", "What percent?", "PERCENT"),
        "highway": make("Highway", "Which highway?", "HWY"),
        "exit": make("Exit", "Which exit?", "EXIT"),
        "volume": make("Qty", "What quantity?", "QTY"),
    ]
}

extension CatalogSlot {
    func optionsShuffled(using rng: inout some RandomNumberGenerator) -> [SlotValue] {
        ([value] + distractors).shuffled(using: &rng)
    }
}
