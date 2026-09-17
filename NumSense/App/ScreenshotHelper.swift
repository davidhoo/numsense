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
                model.itemSlotCorrect = [false]
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

        // Daily median progression across 7 days: ~2.2s down to ~1.22s
        let dayFactors: [Double] = [1.75, 1.55, 1.40, 1.25, 1.12, 1.05, 0.95]

        for dayOffset in (0..<7).reversed() {
            guard let sessionDate = cal.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
            let factorIndex = 6 - dayOffset
            let speedFactor = dayFactors[factorIndex]
            let isToday = dayOffset == 0

            let items: [(itemId: String, sc: String, text: String, slots: [(role: String, visual: String, val: SlotValue, baseMs: Int, ok: Bool, tag: String?)])] = [
                ("time-0315-alt", "time", "It's a quarter after three.", [("clock", "clock", SlotValue(type: "clock", hour: 3, minute: 15), 1250, true, nil)]),
                ("room-402-0", "room", "Your room number is four oh two.", [("room", "door", SlotValue(type: "door", text: "402"), 1350, true, nil)]),
                ("money-1250-8", "money", "Twelve dollars and fifty cents.", [("price", "price", SlotValue(type: "price", cents: 1250), 1080, true, nil)]),
                ("travel-exit-14", "travel", "Take exit fourteen B.", [("exit", "exit", SlotValue(type: "exit", text: "14B"), 1180, true, nil)]),
                ("mix-air-218-c18", "mixed", "Flight two eighteen, gate C eighteen.", [
                    ("flight", "flight", SlotValue(type: "flight", text: "218"), 1400, true, nil),
                    ("gate", "gate", SlotValue(type: "gate", letter: "C", number: 18), 1580, true, nil)
                ]),
                ("measures-temp-72", "measures", "It's seventy two degrees outside.", [("temperature", "temperature", SlotValue(type: "temperature", degrees: 72), 1220, true, nil)]),
                ("date-oct-23", "date", "Our flight is on October twenty-third.", [("calendar", "calendar", SlotValue(type: "calendar", month: 10, day: 23), 1260, true, nil)]),
                ("phone-chunk-800", "phone", "Call us at eight hundred, five five five.", [
                    ("phone", "phone", SlotValue(type: "phone", text: "800"), 1320, true, nil),
                    ("phone", "phone", SlotValue(type: "phone", text: "555"), 2150, isToday ? false : (dayOffset % 2 == 0), "speed-decay")
                ]),
                ("address-oak-742", "address", "Seven forty two Evergreen Terrace.", [("address", "address", SlotValue(type: "address", text: "742"), 1300, true, nil)]),
                ("time-0845-0", "time", "It's eight forty-five.", [("clock", "clock", SlotValue(type: "clock", hour: 8, minute: 45), 1180, true, nil)])
            ]

            var itemAttempts: [ItemAttemptRecord] = []
            var sessionTotalSlots = 0
            var sessionCorrectSlots = 0

            for (itemId, sc, text, slotDefs) in items {
                var slotRecords: [SlotAttemptRecord] = []
                var itemCorrect = true
                for (idx, slotDef) in slotDefs.enumerated() {
                    let adjustedMs = Int(Double(slotDef.baseMs) * speedFactor)
                    let slotOk = isToday ? slotDef.ok : (slotDef.ok && (dayOffset < 3 || idx == 0))
                    if !slotOk { itemCorrect = false }
                    sessionTotalSlots += 1
                    if slotOk { sessionCorrectSlots += 1 }

                    slotRecords.append(
                        SlotAttemptRecord(
                            id: UUID(),
                            slotId: "\(idx)",
                            slotIndex: idx,
                            role: slotDef.role,
                            visual: slotDef.visual,
                            correctValue: slotDef.val,
                            chosenValue: slotDef.val,
                            distractors: [],
                            firstTapCorrect: slotOk,
                            responseMs: adjustedMs,
                            replayedAfterWrong: !slotOk,
                            confusionTag: slotDef.tag
                        )
                    )
                }

                itemAttempts.append(
                    ItemAttemptRecord(
                        id: UUID(),
                        itemId: itemId,
                        scenario: sc,
                        scriptText: text,
                        audioFile: "\(itemId).m4a",
                        variantTags: [],
                        presentedAt: sessionDate,
                        itemFirstListenCorrect: itemCorrect,
                        slotAttempts: slotRecords
                    )
                )
            }

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
                itemCount: itemAttempts.count,
                slotCount: sessionTotalSlots,
                firstListenCorrectSlots: sessionCorrectSlots,
                itemAttempts: itemAttempts
            )
            log.append(session)
        }
    }
}
#endif
