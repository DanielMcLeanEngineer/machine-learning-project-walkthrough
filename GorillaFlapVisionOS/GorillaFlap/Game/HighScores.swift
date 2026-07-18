import Foundation

/// Local top-5 high-score table, persisted as JSON in UserDefaults. Independent of Game
/// Center so scores are always available offline.
@MainActor
final class HighScores: ObservableObject {

    static let shared = HighScores()

    struct Entry: Codable, Identifiable {
        var id = UUID()
        let score: Int
        let date: Date
    }

    @Published private(set) var entries: [Entry] = []

    private let key = "gf.highScores"
    private let maxEntries = 5

    private init() { load() }

    /// Record a finished run. Returns the 1-based rank if it made the table, else nil.
    @discardableResult
    func record(score: Int) -> Int? {
        guard score > 0 else { return nil }
        var updated = entries
        updated.append(Entry(score: score, date: Date()))
        updated.sort { $0.score > $1.score }
        if updated.count > maxEntries { updated = Array(updated.prefix(maxEntries)) }
        entries = updated
        save()
        return entries.firstIndex(where: { $0.score == score })
            .flatMap { entries.contains(where: { $0.score == score }) ? $0 + 1 : nil }
    }

    /// Reset the table — used by unit tests to isolate cases.
    func clearForTesting() {
        entries = []
        save()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([Entry].self, from: data) else { return }
        entries = decoded
    }

    private func save() {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
