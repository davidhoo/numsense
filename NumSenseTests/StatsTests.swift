import Foundation
import Testing
@testable import NumSense

struct StatsTests {
    @Test func medianCalculation() {
        #expect(AttemptLog.median(of: []) == nil)
        #expect(AttemptLog.median(of: [0, -10]) == nil)
        #expect(AttemptLog.median(of: [1200]) == 1200)
        #expect(AttemptLog.median(of: [1000, 3000, 2000]) == 2000)
        #expect(AttemptLog.median(of: [1000, 2000, 3000, 4000]) == 2500)
    }

    @Test func speedTierThresholds() {
        #expect(SpeedTier.tier(for: 800) == SpeedTier.reflex)
        #expect(SpeedTier.tier(for: 1499) == SpeedTier.reflex)
        #expect(SpeedTier.tier(for: 1500) == SpeedTier.fluent)
        #expect(SpeedTier.tier(for: 2499) == SpeedTier.fluent)
        #expect(SpeedTier.tier(for: 2500) == SpeedTier.deliberate)
        #expect(SpeedTier.tier(for: 5000) == SpeedTier.deliberate)
    }

    @Test func attemptLogAnalyticsWithMockData() {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let fileURL = tempDir.appendingPathComponent("test-attempt-log.json")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let log = AttemptLog(fileURL: fileURL)

        let slot1 = SlotAttemptRecord(
            id: UUID(),
            slotId: "s1",
            slotIndex: 0,
            role: "hour",
            visual: "clock",
            correctValue: SlotValue(type: "clock", hour: 3, minute: 0),
            chosenValue: SlotValue(type: "clock", hour: 3, minute: 0),
            distractors: [],
            firstTapCorrect: true,
            responseMs: 1200,
            replayedAfterWrong: false,
            confusionTag: nil
        )

        let slot2 = SlotAttemptRecord(
            id: UUID(),
            slotId: "s2",
            slotIndex: 1,
            role: "minute",
            visual: "clock",
            correctValue: SlotValue(type: "clock", hour: 3, minute: 15),
            chosenValue: SlotValue(type: "clock", hour: 3, minute: 50),
            distractors: [],
            firstTapCorrect: false,
            responseMs: 2800,
            replayedAfterWrong: true,
            confusionTag: "teen-ty"
        )

        let item = ItemAttemptRecord(
            id: UUID(),
            itemId: "test-item-1",
            scenario: "time",
            scriptText: "It is three fifteen.",
            audioFile: "audio.m4a",
            variantTags: [],
            presentedAt: .now,
            itemFirstListenCorrect: false,
            slotAttempts: [slot1, slot2]
        )

        let session = SessionRecord(
            id: UUID(),
            schemaVersion: 1,
            startedAt: .now,
            endedAt: .now,
            completed: true,
            source: "practice",
            scenarioFilter: "all",
            settings: SettingsSnapshot(clockStyle: "realistic", timeFormat: "12h", sessionLength: 8, playInSilentMode: false),
            itemCount: 1,
            slotCount: 2,
            firstListenCorrectSlots: 1,
            itemAttempts: [item]
        )

        log.append(session)

        #expect(session.allSlotAttemptsFlat.count == 2)
        #expect(session.medianResponseMs == 2000)
        #expect(session.correctMedianResponseMs == 1200)
        #expect(session.speedTier == SpeedTier.fluent)

        let past = Calendar.current.date(byAdding: .day, value: -1, to: .now) ?? .now
        #expect(log.medianResponseMs(since: past) == 2000)
        #expect(log.medianResponseMs(since: past, correctOnly: true) == 1200)

        let scenarios = log.scenarioSpeedAndAccuracy(since: past)
        #expect(scenarios.count == 1)
        #expect(scenarios.first?.scenario == .time)
        #expect(scenarios.first?.medianMs == 2000)
        #expect(scenarios.first?.accuracy == 0.5)

        let slots = log.slotIndexSpeedAndAccuracy(since: past)
        #expect(slots.count == 2)
        #expect(slots[0].slotIndex == 0 && slots[0].medianMs == 1200)
        #expect(slots[1].slotIndex == 1 && slots[1].medianMs == 2800)

        let trends = log.dailySpeedTrend(since: past)
        #expect(trends.count == 1)
        #expect(trends.first?.medianMs == 2000)
        #expect(trends.first?.accuracy == 0.5)
    }
}
