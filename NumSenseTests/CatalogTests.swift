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
}
