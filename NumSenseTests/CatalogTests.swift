import Foundation
import Testing
@testable import NumSense

struct CatalogTests {
    @Test func bundledCatalogLoads() throws {
        let url = try #require(Bundle.main.url(forResource: "catalog", withExtension: "json"))
        let data = try Data(contentsOf: url)
        let file = try JSONDecoder().decode(CatalogFile.self, from: data)
        #expect(file.items.count >= 100)
        let scenarios = Set(file.items.map(\.scenario))
        for scenario in Scenario.allCases {
            #expect(scenarios.contains(scenario))
        }
        let mixed = file.items.filter { $0.scenario == .mixed }
        #expect(mixed.count >= 15)
    }

    @Test func spokenTextHasNoRawDigits() throws {
        let store = CatalogStore.loadBundled()
        #expect(!store.items.isEmpty)
        for item in store.items {
            #expect(item.spokenText.rangeOfCharacter(from: .decimalDigits) == nil)
            #expect(!item.spokenText.contains("$"))
            #expect(item.slots.count >= 1)
            for slot in item.slots {
                #expect(slot.distractors.count == 3)
            }
        }
    }

    @Test func mixedItemsHaveMultipleSlots() throws {
        let mixed = CatalogStore.loadBundled().items.filter { $0.scenario == .mixed }
        #expect(mixed.allSatisfy { $0.slots.count >= 2 })
    }

    @Test func slotQuestionsNameTheAskedNumber() throws {
        let store = CatalogStore.loadBundled()
        #expect(!store.items.isEmpty)

        func question(_ id: String, _ index: Int) throws -> SlotQuestion {
            let item = try #require(store.byID[id])
            return SlotQuestion.resolve(slots: item.slots, index: index)
        }

        #expect(try question("mix-hotel-3-412-4", 0).title == "Time")
        #expect(try question("mix-hotel-3-412-4", 1).title == "Room")
        #expect(try question("mix-hotel-3-412-4", 2).title == "Floor")
        #expect(try question("mix-hotel-3-412-4", 2).cardCaption == "FLOOR")

        #expect(try question("mix-check-4260-50-740", 0).title == "Bill")
        #expect(try question("mix-check-4260-50-740", 1).title == "Paid")
        #expect(try question("mix-check-4260-50-740", 2).title == "Change")

        #expect(try question("mix-tip-4860-20", 0).title == "Bill")
        #expect(try question("mix-tip-4860-20", 1).title == "Percent")
        #expect(try question("mix-tip-4860-20", 2).title == "Tip")

        #expect(try question("phone-415-area", 0).title == "Area")
        #expect(try question("phone-415-area", 1).title == "Prefix")
        #expect(try question("phone-415-area", 2).title == "Last 4")
        #expect(try question("phone-415-area", 0).phoneGroupCount == 3)

        #expect(try question("time-open-9-6", 0).title == "Opens")
        #expect(try question("time-open-9-6", 1).title == "Closes")

        #expect(try question("date-03-05-0", 0).title == "Date")
        #expect(try question("date-03-05-0", 1).emphasizeWeekday)

        #expect(try question("room-floor-12-1215", 0).cardCaption == "FLOOR")
        #expect(try question("room-floor-12-1215", 1).cardCaption == "ROOM")
        #expect(try question("travel-p2-114", 0).title == "Level")
        #expect(try question("travel-p2-114", 1).title == "Space")
    }
}
