#if DEBUG
import Foundation

enum ScreenshotHelper {
    static func configure(model: AppModel) -> String? {
        let args = ProcessInfo.processInfo.arguments
        guard let idx = args.firstIndex(of: "-ScreenshotMode"), idx + 1 < args.count else {
            return nil
        }
        let mode = args[idx + 1]
        seedMockLog(model.log)

        switch mode {
        case "home":
            model.phase = .idle
            return mode

        case "practice_clock":
            if let item = model.catalog.byID["time-0315-alt"] {
                model.settings.clockStyle = .analog
                model.queue = Array(repeating: item, count: 12)
                model.itemIndex = 2
                model.slotIndex = 0
                let slot = item.slots[0]
                model.live = LiveSlotState(options: [slot.value] + slot.distractors, chosen: nil)
                model.phase = .options
            }
            return mode

        case "practice_multistep":
            if let item = model.catalog.byID["mix-air-218-c18"] {
                model.queue = Array(repeating: item, count: 12)
                model.itemIndex = 5
                model.slotIndex = 1
                let slot = item.slots[1]
                model.live = LiveSlotState(options: [slot.value] + slot.distractors, chosen: nil)
                model.phase = .options
            }
            return mode

        case "feedback":
            if let item = model.catalog.byID["room-402-0"] {
                model.queue = Array(repeating: item, count: 12)
                model.itemIndex = 3
                model.slotIndex = 0
                let slot = item.slots[0]
                let wrongChoice = slot.distractors.first ?? slot.value
                model.live = LiveSlotState(
                    options: [wrongChoice, slot.value] + Array(slot.distractors.dropFirst().prefix(2)),
                    chosen: wrongChoice
                )
                model.phase = .feedback
            }
            return mode

        case "summary":
            if let session = model.log.sessions.first {
                model.lastFinished = session
                model.phase = .summary
            }
            return mode

        case "stats":
            return mode

        default:
            return nil
        }
    }

    private static func seedMockLog(_ log: AttemptLog) {
        log.deleteAll()
        let cal = Calendar.current
        let now = Date()

        for dayOffset in (0..<5).reversed() {
            guard let sessionDate = cal.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
            let isToday = dayOffset == 0
            let correctCount = isToday ? 11 : 10

            let itemAttempts: [ItemAttemptRecord] = [
                ItemAttemptRecord(
                    id: UUID(),
                    itemId: "time-0315-alt",
                    scenario: "time",
                    scriptText: "It's a quarter after three.",
                    audioFile: "time-0315-alt.m4a",
                    variantTags: ["quarter-after"],
                    presentedAt: sessionDate,
                    itemFirstListenCorrect: true,
                    slotAttempts: [
                        SlotAttemptRecord(
                            id: UUID(),
                            slotId: "t",
                            slotIndex: 0,
                            role: "clock",
                            visual: "clock",
                            correctValue: SlotValue(type: "clock", hour: 3, minute: 15),
                            chosenValue: SlotValue(type: "clock", hour: 3, minute: 15),
                            distractors: [],
                            firstTapCorrect: true,
                            responseMs: 1400,
                            replayedAfterWrong: false,
                            confusionTag: nil
                        )
                    ]
                ),
                ItemAttemptRecord(
                    id: UUID(),
                    itemId: "room-402-0",
                    scenario: "room",
                    scriptText: "Your room number is four oh two.",
                    audioFile: "room-402-0.m4a",
                    variantTags: [],
                    presentedAt: sessionDate,
                    itemFirstListenCorrect: false,
                    slotAttempts: [
                        SlotAttemptRecord(
                            id: UUID(),
                            slotId: "r",
                            slotIndex: 0,
                            role: "room",
                            visual: "door",
                            correctValue: SlotValue(type: "door", text: "402"),
                            chosenValue: SlotValue(type: "door", text: "420"),
                            distractors: [],
                            firstTapCorrect: false,
                            responseMs: 2100,
                            replayedAfterWrong: true,
                            confusionTag: "oh-vs-hundred"
                        )
                    ]
                ),
                ItemAttemptRecord(
                    id: UUID(),
                    itemId: "money-1250-8",
                    scenario: "money",
                    scriptText: "Twelve dollars and fifty cents.",
                    audioFile: "money-1250-8.m4a",
                    variantTags: [],
                    presentedAt: sessionDate,
                    itemFirstListenCorrect: true,
                    slotAttempts: [
                        SlotAttemptRecord(
                            id: UUID(),
                            slotId: "m",
                            slotIndex: 0,
                            role: "price",
                            visual: "price",
                            correctValue: SlotValue(type: "price", cents: 1250),
                            chosenValue: SlotValue(type: "price", cents: 1250),
                            distractors: [],
                            firstTapCorrect: true,
                            responseMs: 1200,
                            replayedAfterWrong: false,
                            confusionTag: nil
                        )
                    ]
                ),
                ItemAttemptRecord(
                    id: UUID(),
                    itemId: "mix-air-218-c18",
                    scenario: "mixed",
                    scriptText: "Flight two eighteen, gate C eighteen.",
                    audioFile: "mix-air-218-c18.m4a",
                    variantTags: ["airport"],
                    presentedAt: sessionDate,
                    itemFirstListenCorrect: true,
                    slotAttempts: [
                        SlotAttemptRecord(
                            id: UUID(),
                            slotId: "f",
                            slotIndex: 0,
                            role: "flight",
                            visual: "flight",
                            correctValue: SlotValue(type: "flight", text: "218"),
                            chosenValue: SlotValue(type: "flight", text: "218"),
                            distractors: [],
                            firstTapCorrect: true,
                            responseMs: 1600,
                            replayedAfterWrong: false,
                            confusionTag: nil
                        ),
                        SlotAttemptRecord(
                            id: UUID(),
                            slotId: "g",
                            slotIndex: 1,
                            role: "gate",
                            visual: "gate",
                            correctValue: SlotValue(type: "gate", letter: "C", number: 18),
                            chosenValue: SlotValue(type: "gate", letter: "C", number: 18),
                            distractors: [],
                            firstTapCorrect: true,
                            responseMs: 1500,
                            replayedAfterWrong: false,
                            confusionTag: nil
                        )
                    ]
                )
            ]

            let session = SessionRecord(
                id: UUID(),
                schemaVersion: 1,
                startedAt: sessionDate,
                endedAt: sessionDate.addingTimeInterval(180),
                completed: true,
                source: "practice",
                scenarioFilter: "all",
                settings: SettingsSnapshot(
                    clockStyle: "analog",
                    timeFormat: "twelve",
                    sessionLength: 12,
                    playInSilentMode: true
                ),
                itemCount: 4,
                slotCount: 12,
                firstListenCorrectSlots: correctCount,
                itemAttempts: itemAttempts
            )
            log.append(session)
        }
    }
}
#endif
