import Foundation
import SwiftUI

enum SpeedTier: String, Codable, CaseIterable, Identifiable {
    case reflex
    case fluent
    case deliberate

    var id: String { rawValue }

    var title: String {
        switch self {
        case .reflex: return "Reflex"
        case .fluent: return "Fluent"
        case .deliberate: return "Deliberate"
        }
    }

    var localizedTitle: String {
        switch self {
        case .reflex: return "直觉神速"
        case .fluent: return "顺畅反应"
        case .deliberate: return "思考心译"
        }
    }

    var systemImage: String {
        switch self {
        case .reflex: return "bolt.fill"
        case .fluent: return "hare.fill"
        case .deliberate: return "tortoise.fill"
        }
    }

    var color: Color {
        switch self {
        case .reflex: return .green
        case .fluent: return .blue
        case .deliberate: return .orange
        }
    }

    static func tier(for ms: Int) -> SpeedTier {
        if ms < 1500 { return .reflex }
        if ms < 2500 { return .fluent }
        return .deliberate
    }
}

struct DailySpeedTrend: Identifiable, Hashable {
    var id: Date { date }
    var date: Date
    var medianMs: Int
    var accuracy: Double
    var count: Int

    var medianSeconds: Double {
        Double(medianMs) / 1000.0
    }
}

struct ScenarioSpeedAccuracy: Identifiable, Hashable {
    var id: String { scenario.rawValue }
    var scenario: Scenario
    var medianMs: Int
    var accuracy: Double
    var count: Int

    var tier: SpeedTier {
        SpeedTier.tier(for: medianMs)
    }

    var medianSeconds: Double {
        Double(medianMs) / 1000.0
    }
}

struct SlotIndexSpeedAccuracy: Identifiable, Hashable {
    var id: Int { slotIndex }
    var slotIndex: Int
    var medianMs: Int
    var accuracy: Double
    var count: Int

    var medianSeconds: Double {
        Double(medianMs) / 1000.0
    }
}

struct SettingsSnapshot: Codable, Hashable {
    var clockStyle: String
    var timeFormat: String
    var sessionLength: Int
    var playInSilentMode: Bool
}

struct SessionRecord: Codable, Identifiable, Hashable {
    var id: UUID
    var schemaVersion: Int
    var startedAt: Date
    var endedAt: Date?
    var completed: Bool
    var source: String
    var scenarioFilter: String
    var settings: SettingsSnapshot
    var itemCount: Int
    var slotCount: Int
    var firstListenCorrectSlots: Int
    var itemAttempts: [ItemAttemptRecord]

    var allSlotAttemptsFlat: [SlotAttemptRecord] {
        itemAttempts.flatMap(\.slotAttempts)
    }

    var medianResponseMs: Int? {
        AttemptLog.median(of: allSlotAttemptsFlat.map(\.responseMs))
    }

    var correctMedianResponseMs: Int? {
        AttemptLog.median(of: allSlotAttemptsFlat.filter(\.firstTapCorrect).map(\.responseMs))
    }

    var speedTier: SpeedTier {
        guard let ms = medianResponseMs else { return .fluent }
        return SpeedTier.tier(for: ms)
    }
}

struct ItemAttemptRecord: Codable, Identifiable, Hashable {
    var id: UUID
    var itemId: String
    var scenario: String
    var scriptText: String
    var audioFile: String
    var variantTags: [String]
    var presentedAt: Date
    var itemFirstListenCorrect: Bool
    var slotAttempts: [SlotAttemptRecord]
}

struct SlotAttemptRecord: Codable, Identifiable, Hashable {
    var id: UUID
    var slotId: String
    var slotIndex: Int
    var role: String
    var visual: String
    var correctValue: SlotValue
    var chosenValue: SlotValue
    var distractors: [SlotValue]
    var firstTapCorrect: Bool
    var responseMs: Int
    var replayedAfterWrong: Bool
    var confusionTag: String?
}

@Observable
final class AttemptLog {
    private(set) var sessions: [SessionRecord] = []
    private let url: URL
    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }()
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    init(fileURL: URL? = nil) {
        if let fileURL {
            url = fileURL
        } else {
            let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
                .appendingPathComponent("NumSense", isDirectory: true)
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            url = dir.appendingPathComponent("attempt-log.json")
        }
        load()
    }

    func append(_ session: SessionRecord) {
        sessions.insert(session, at: 0)
        save()
    }

    func deleteAll() {
        sessions = []
        save()
    }

    var allSlotAttempts: [(SessionRecord, ItemAttemptRecord, SlotAttemptRecord)] {
        sessions.flatMap { session in
            session.itemAttempts.flatMap { item in
                item.slotAttempts.map { (session, item, $0) }
            }
        }
    }

    func accuracy(since start: Date, source: String? = "practice") -> Double {
        let rows = allSlotAttempts.filter { session, _, slot in
            session.startedAt >= start && (source == nil || session.source == source)
        }
        guard !rows.isEmpty else { return 0 }
        let ok = rows.filter { $0.2.firstTapCorrect }.count
        return Double(ok) / Double(rows.count)
    }

    func accuracyByScenario(since start: Date) -> [(Scenario, Double, Int)] {
        let rows = allSlotAttempts.filter { $0.0.startedAt >= start && $0.0.source == "practice" }
        return Scenario.allCases.compactMap { scenario in
            let subset = rows.filter { $0.1.scenario == scenario.rawValue }
            guard !subset.isEmpty else { return nil }
            let ok = subset.filter { $0.2.firstTapCorrect }.count
            return (scenario, Double(ok) / Double(subset.count), subset.count)
        }
    }

    static func median(of values: [Int]) -> Int? {
        let valid = values.filter { $0 > 0 }.sorted()
        guard !valid.isEmpty else { return nil }
        let count = valid.count
        if count % 2 == 1 {
            return valid[count / 2]
        } else {
            return (valid[(count / 2) - 1] + valid[count / 2]) / 2
        }
    }

    func medianResponseMs(since start: Date, source: String? = "practice", correctOnly: Bool = false) -> Int? {
        let rows = allSlotAttempts.filter { session, _, slot in
            session.startedAt >= start &&
            (source == nil || session.source == source) &&
            slot.responseMs > 0 &&
            (!correctOnly || slot.firstTapCorrect)
        }
        return Self.median(of: rows.map(\.2.responseMs))
    }

    func scenarioSpeedAndAccuracy(since start: Date, source: String? = "practice") -> [ScenarioSpeedAccuracy] {
        let rows = allSlotAttempts.filter { session, _, slot in
            session.startedAt >= start &&
            (source == nil || session.source == source) &&
            slot.responseMs > 0
        }
        return Scenario.allCases.compactMap { sc in
            let subset = rows.filter { $0.1.scenario == sc.rawValue }
            guard !subset.isEmpty else { return nil }
            guard let med = Self.median(of: subset.map(\.2.responseMs)) else { return nil }
            let ok = subset.filter(\.2.firstTapCorrect).count
            let acc = Double(ok) / Double(subset.count)
            return ScenarioSpeedAccuracy(scenario: sc, medianMs: med, accuracy: acc, count: subset.count)
        }
    }

    func slotIndexSpeedAndAccuracy(since start: Date, source: String? = "practice") -> [SlotIndexSpeedAccuracy] {
        let rows = allSlotAttempts.filter { session, _, slot in
            session.startedAt >= start &&
            (source == nil || session.source == source) &&
            slot.responseMs > 0
        }
        let indexes = Set(rows.map(\.2.slotIndex)).sorted()
        return indexes.compactMap { idx in
            let subset = rows.filter { $0.2.slotIndex == idx }
            guard !subset.isEmpty, let med = Self.median(of: subset.map(\.2.responseMs)) else { return nil }
            let ok = subset.filter(\.2.firstTapCorrect).count
            let acc = Double(ok) / Double(subset.count)
            return SlotIndexSpeedAccuracy(slotIndex: idx, medianMs: med, accuracy: acc, count: subset.count)
        }
    }

    func dailySpeedTrend(since start: Date, source: String? = "practice") -> [DailySpeedTrend] {
        let cal = Calendar.current
        let rows = allSlotAttempts.filter { session, _, slot in
            session.startedAt >= start &&
            (source == nil || session.source == source) &&
            slot.responseMs > 0
        }
        let grouped = Dictionary(grouping: rows) { row in
            cal.startOfDay(for: row.0.startedAt)
        }
        return grouped.keys.sorted().compactMap { day in
            guard let items = grouped[day], !items.isEmpty else { return nil }
            let msList = items.map(\.2.responseMs)
            guard let med = Self.median(of: msList) else { return nil }
            let ok = items.filter(\.2.firstTapCorrect).count
            let acc = Double(ok) / Double(items.count)
            return DailySpeedTrend(date: day, medianMs: med, accuracy: acc, count: items.count)
        }
    }

    func slotIndexAccuracy(since start: Date) -> [(Int, Double, Int)] {
        let rows = allSlotAttempts.filter { $0.0.startedAt >= start && $0.0.source == "practice" }
        let indexes = Set(rows.map(\.2.slotIndex)).sorted()
        return indexes.map { idx in
            let subset = rows.filter { $0.2.slotIndex == idx }
            let ok = subset.filter { $0.2.firstTapCorrect }.count
            return (idx, subset.isEmpty ? 0 : Double(ok) / Double(subset.count), subset.count)
        }
    }

    func confusionPairs(since start: Date, minimum: Int = 3) -> [(String, Int)] {
        var counts: [String: Int] = [:]
        for (session, _, slot) in allSlotAttempts {
            guard session.startedAt >= start, session.source == "practice", !slot.firstTapCorrect else { continue }
            let key = slot.confusionTag ?? "\(slot.role):miss"
            counts[key, default: 0] += 1
        }
        return counts.map { ($0.key, $0.value) }.sorted { $0.1 > $1.1 }.filter { $0.1 >= minimum }
    }

    func missedItemIDs(days: Int = 14) -> [String] {
        let start = Calendar.current.date(byAdding: .day, value: -days, to: .now) ?? .now
        var last: [String: Bool] = [:]
        for session in sessions.reversed() where session.startedAt >= start {
            for item in session.itemAttempts {
                last[item.itemId] = item.itemFirstListenCorrect
            }
        }
        return last.filter { !$0.value }.map(\.key)
    }

    func completionStreak() -> Int {
        let days = Set(sessions.filter(\.completed).map { Calendar.current.startOfDay(for: $0.startedAt) })
        var streak = 0
        var day = Calendar.current.startOfDay(for: .now)
        while days.contains(day) {
            streak += 1
            guard let prev = Calendar.current.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return streak
    }

    private func load() {
        guard let data = try? Data(contentsOf: url) else { return }
        sessions = (try? decoder.decode([SessionRecord].self, from: data)) ?? []
    }

    private func save() {
        guard let data = try? encoder.encode(sessions) else { return }
        try? data.write(to: url, options: .atomic)
    }
}

enum ExportBuilder {
    static func jsonData(from log: AttemptLog) throws -> Data {
        struct Box: Encodable {
            var schemaVersion: Int
            var exportedAt: Date
            var sessions: [SessionRecord]
        }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(Box(schemaVersion: 1, exportedAt: .now, sessions: log.sessions))
    }

    static func csv(from log: AttemptLog) -> String {
        var rows = [
            "session_id,session_started_at,source,scenario_filter,clock_style,item_id,scenario,script_text,slot_index,role,visual,correct_value,chosen_value,first_tap_correct,response_ms,replayed_after_wrong,confusion_tag,item_first_listen_correct"
        ]
        let iso = ISO8601DateFormatter()
        for session in log.sessions {
            for item in session.itemAttempts {
                for slot in item.slotAttempts {
                    let fields: [String] = [
                        session.id.uuidString,
                        iso.string(from: session.startedAt),
                        session.source,
                        session.scenarioFilter,
                        session.settings.clockStyle,
                        item.itemId,
                        csvEscape(item.scenario),
                        csvEscape(item.scriptText),
                        String(slot.slotIndex),
                        csvEscape(slot.role),
                        csvEscape(slot.visual),
                        csvEscape(jsonString(slot.correctValue)),
                        csvEscape(jsonString(slot.chosenValue)),
                        slot.firstTapCorrect ? "true" : "false",
                        String(slot.responseMs),
                        slot.replayedAfterWrong ? "true" : "false",
                        csvEscape(slot.confusionTag ?? ""),
                        item.itemFirstListenCorrect ? "true" : "false"
                    ]
                    rows.append(fields.joined(separator: ","))
                }
            }
        }
        return rows.joined(separator: "\n") + "\n"
    }

    private static func jsonString(_ value: SlotValue) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        guard let data = try? encoder.encode(value), let s = String(data: data, encoding: .utf8) else { return "" }
        return s
    }

    private static func csvEscape(_ raw: String) -> String {
        if raw.contains(",") || raw.contains("\"") || raw.contains("\n") {
            return "\"" + raw.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return raw
    }
}
