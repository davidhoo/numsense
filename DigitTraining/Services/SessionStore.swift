import Foundation

struct SessionStore: Sendable {
    private let defaults: UserDefaults
    private let key = "digit-training.records"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> [DrillRecord] {
        guard let data = defaults.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([DrillRecord].self, from: data)) ?? []
    }

    func save(_ records: [DrillRecord]) {
        let trimmed = Array(records.sorted { $0.finishedAt > $1.finishedAt }.prefix(200))
        defaults.set(try? JSONEncoder().encode(trimmed), forKey: key)
    }

    func append(_ record: DrillRecord) {
        var records = load()
        records.insert(record, at: 0)
        save(records)
    }
}
