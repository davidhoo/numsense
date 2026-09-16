import Foundation

struct CatalogStore: Sendable {
    let items: [CatalogItem]
    let byID: [String: CatalogItem]

    init(items: [CatalogItem]) {
        self.items = items
        self.byID = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
    }

    static func loadBundled() -> CatalogStore {
        let url = Bundle.main.url(forResource: "catalog", withExtension: "json")
            ?? Bundle.main.url(forResource: "catalog", withExtension: "json", subdirectory: "Content")
        guard let url, let data = try? Data(contentsOf: url) else {
            return CatalogStore(items: [])
        }
        do {
            let file = try JSONDecoder().decode(CatalogFile.self, from: data)
            return CatalogStore(items: file.items)
        } catch {
            assertionFailure("catalog.json decode failed: \(error)")
            return CatalogStore(items: [])
        }
    }

    func items(matching scenario: Scenario?) -> [CatalogItem] {
        guard let scenario else { return items }
        return items.filter { $0.scenario == scenario }
    }
}
