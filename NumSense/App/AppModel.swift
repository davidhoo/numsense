import Foundation
import Observation

enum TrialPhase: Equatable {
    case idle
    case listen
    case waiting
    case options
    case feedback
    case summary
}

struct LiveSlotState: Equatable {
    var options: [SlotValue]
    var chosen: SlotValue?
}

@Observable
final class AppModel {
    var settings: AppSettings {
        didSet { persistSettings() }
    }
    var catalog: CatalogStore
    var log: AttemptLog
    var audio = AudioPlayerService()

    var phase: TrialPhase = .idle
    var source: String = "practice"
    var queue: [CatalogItem] = []
    var itemIndex = 0
    var slotIndex = 0
    var live: LiveSlotState?
    var itemSlotCorrect: [Bool] = []
    var sessionStartedAt: Date?
    var draftItems: [ItemAttemptRecord] = []
    var currentSlotStartedAt: Date?
    var playGeneration = 0
    var lastFinished: SessionRecord?

    var currentItem: CatalogItem? {
        guard queue.indices.contains(itemIndex) else { return nil }
        return queue[itemIndex]
    }

    var currentSlot: CatalogSlot? {
        guard let item = currentItem, item.slots.indices.contains(slotIndex) else { return nil }
        return item.slots[slotIndex]
    }

    var progressLabel: String {
        guard !queue.isEmpty else { return "" }
        return "Item \(itemIndex + 1) of \(queue.count)"
    }

    var currentQuestion: SlotQuestion {
        guard let item = currentItem else { return .generic }
        return SlotQuestion.resolve(slots: item.slots, index: slotIndex)
    }

    var lastAnswerWasWrong: Bool {
        guard let slot = currentSlot, let chosen = live?.chosen else { return false }
        return chosen != slot.value
    }

    init(catalog: CatalogStore = .loadBundled(), log: AttemptLog = AttemptLog()) {
        self.catalog = catalog
        self.log = log
        if let data = UserDefaults.standard.data(forKey: "numsense.settings"),
           let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) {
            self.settings = decoded
        } else {
            self.settings = .default
        }
        audio.configureSession(playInSilentMode: settings.playInSilentMode)
    }

    var sevenDayAccuracy: Double {
        let start = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
        return log.accuracy(since: start)
    }

    func startPractice() {
        let pool = catalog.items(matching: settings.scenarioFilter)
        var rng = SystemRandomNumberGenerator()
        let picked = Array(pool.shuffled(using: &rng).prefix(settings.sessionLength))
        beginSession(items: picked, source: "practice")
    }

    func startReview() {
        let ids = log.missedItemIDs()
        let items = ids.compactMap { catalog.byID[$0] }
        var rng = SystemRandomNumberGenerator()
        let picked = Array(items.shuffled(using: &rng).prefix(max(settings.sessionLength, 8)))
        beginSession(items: picked, source: "review")
    }

    func beginSession(items: [CatalogItem], source: String) {
        audio.stop()
        self.source = source
        queue = items
        itemIndex = 0
        slotIndex = 0
        draftItems = []
        itemSlotCorrect = []
        lastFinished = nil
        sessionStartedAt = .now
        if queue.isEmpty {
            phase = .summary
            finishSession(completed: true)
            return
        }
        startCurrentItem()
    }

    func endSessionEarly() {
        audio.stop()
        playGeneration += 1
        finishSession(completed: false)
        phase = .summary
    }

    func dismissSummary() {
        phase = .idle
        queue = []
        lastFinished = nil
    }

    func choose(_ value: SlotValue) {
        guard phase == .options, let item = currentItem, let slot = currentSlot, live != nil else { return }
        let correct = value == slot.value
        let ms: Int
        if let start = currentSlotStartedAt {
            ms = Int(Date.now.timeIntervalSince(start) * 1000)
        } else {
            ms = 0
        }
        live?.chosen = value
        itemSlotCorrect.append(correct)
        let attempt = SlotAttemptRecord(
            id: UUID(),
            slotId: slot.id,
            slotIndex: slotIndex,
            role: slot.role,
            visual: slot.visual,
            correctValue: slot.value,
            chosenValue: value,
            distractors: slot.distractors,
            firstTapCorrect: correct,
            responseMs: ms,
            replayedAfterWrong: !correct,
            confusionTag: correct ? nil : guessTag(correct: slot.value, chosen: value, traps: item.trapTags)
        )
        if draftItems.count == itemIndex {
            draftItems.append(
                ItemAttemptRecord(
                    id: UUID(),
                    itemId: item.id,
                    scenario: item.scenario.rawValue,
                    scriptText: item.spokenText,
                    audioFile: item.audioFile,
                    variantTags: item.variantTags,
                    presentedAt: sessionStartedAt ?? .now,
                    itemFirstListenCorrect: false,
                    slotAttempts: [attempt]
                )
            )
        } else {
            draftItems[itemIndex].slotAttempts.append(attempt)
        }

        phase = .feedback
        if correct {
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(350))
                advanceAfterSlot()
            }
        } else {
            playGeneration += 1
            let gen = playGeneration
            audio.replay()
            let wait = max(audio.duration + 1.6, 2.8)
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(wait))
                guard gen == self.playGeneration else { return }
                self.advanceAfterSlot()
            }
        }
    }

    func replayFromEar() {
        guard let item = currentItem else { return }
        switch phase {
        case .listen, .waiting:
            phase = .listen
            playGeneration += 1
            let gen = playGeneration
            audio.playBundled(fileName: item.audioFile, spokenFallback: item.spokenText) { [weak self] in
                Task { @MainActor in
                    guard let self, gen == self.playGeneration else { return }
                    self.phase = .waiting
                    try? await Task.sleep(for: .seconds(1))
                    guard gen == self.playGeneration else { return }
                    self.phase = .options
                    self.currentSlotStartedAt = .now
                }
            }
        case .options, .feedback:
            audio.replay()
        default:
            break
        }
    }

    func verdict(for option: SlotValue) -> SlotOptionCard.Verdict? {
        guard phase == .feedback, let slot = currentSlot, let chosen = live?.chosen else { return nil }
        if option == slot.value { return option == chosen ? .correct : .revealed }
        if option == chosen { return .wrong }
        return nil
    }

    private func startCurrentItem() {
        slotIndex = 0
        itemSlotCorrect = []
        live = nil
        startCurrentSlot(playAudio: true)
    }

    private func startCurrentSlot(playAudio: Bool) {
        guard let item = currentItem, let slot = currentSlot else { return }
        var rng = SystemRandomNumberGenerator()
        live = LiveSlotState(options: slot.optionsShuffled(using: &rng), chosen: nil)
        if playAudio {
            phase = .listen
            playGeneration += 1
            let gen = playGeneration
            audio.configureSession(playInSilentMode: settings.playInSilentMode)
            audio.playBundled(fileName: item.audioFile, spokenFallback: item.spokenText) { [weak self] in
                Task { @MainActor in
                    guard let self, gen == self.playGeneration else { return }
                    self.phase = .waiting
                    try? await Task.sleep(for: .seconds(1))
                    guard gen == self.playGeneration else { return }
                    self.phase = .options
                    self.currentSlotStartedAt = .now
                }
            }
        } else {
            phase = .options
            currentSlotStartedAt = .now
        }
    }

    private func advanceAfterSlot() {
        guard let item = currentItem else { return }
        if slotIndex + 1 < item.slots.count {
            slotIndex += 1
            startCurrentSlot(playAudio: false)
            return
        }
        if draftItems.indices.contains(itemIndex) {
            draftItems[itemIndex].itemFirstListenCorrect = itemSlotCorrect.allSatisfy(\.self)
        }
        if itemIndex + 1 < queue.count {
            itemIndex += 1
            startCurrentItem()
        } else {
            finishSession(completed: true)
            phase = .summary
        }
    }

    private func finishSession(completed: Bool) {
        audio.stop()
        let slotRows = draftItems.flatMap(\.slotAttempts)
        let record = SessionRecord(
            id: UUID(),
            schemaVersion: 1,
            startedAt: sessionStartedAt ?? .now,
            endedAt: .now,
            completed: completed,
            source: source,
            scenarioFilter: settings.scenarioFilter?.rawValue ?? "all",
            settings: SettingsSnapshot(
                clockStyle: settings.clockStyle.rawValue,
                timeFormat: settings.timeFormat.rawValue,
                sessionLength: settings.sessionLength,
                playInSilentMode: settings.playInSilentMode
            ),
            itemCount: queue.count,
            slotCount: slotRows.count,
            firstListenCorrectSlots: slotRows.filter(\.firstTapCorrect).count,
            itemAttempts: draftItems
        )
        if !draftItems.isEmpty {
            log.append(record)
        }
        lastFinished = record
        phase = .summary
    }

    private func persistSettings() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: "numsense.settings")
        }
        audio.configureSession(playInSilentMode: settings.playInSilentMode)
    }

    private func guessTag(correct: SlotValue, chosen: SlotValue, traps: [String]) -> String {
        if correct.type == "clock", chosen.type == "clock",
           let cm = correct.minute, let ym = chosen.minute {
            let pair = Set([cm, ym])
            if pair == [15, 50] || pair == [13, 30] || pair == [14, 40] { return "teen-ty" }
        }
        return traps.first ?? "miss"
    }
}
