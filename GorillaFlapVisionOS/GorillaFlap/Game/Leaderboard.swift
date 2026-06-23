import GameKit

/// Thin Game Center wrapper: authenticates the local player and submits the best score.
/// Everything is best-effort — if Game Center is unavailable or the player declines,
/// the game plays exactly the same, just without an online board.
@MainActor
final class Leaderboard: ObservableObject {

    static let shared = Leaderboard()

    /// Configure this ID to match the leaderboard you create in App Store Connect.
    static let leaderboardID = "com.danielmclean.gorillaflap.highscores"

    @Published private(set) var isAuthenticated = false

    private init() {}

    /// Kick off authentication. On visionOS this presents Apple's sign-in UI if needed.
    func authenticate() {
        GKLocalPlayer.local.authenticateHandler = { [weak self] _, error in
            Task { @MainActor in
                self?.isAuthenticated = GKLocalPlayer.local.isAuthenticated
                if let error { print("Game Center auth: \(error.localizedDescription)") }
            }
        }
    }

    func submit(score: Int) async {
        guard GKLocalPlayer.local.isAuthenticated else { return }
        do {
            try await GKLeaderboard.submitScore(
                score,
                context: 0,
                player: GKLocalPlayer.local,
                leaderboardIDs: [Self.leaderboardID]
            )
        } catch {
            print("Game Center submit failed: \(error.localizedDescription)")
        }
    }
}
