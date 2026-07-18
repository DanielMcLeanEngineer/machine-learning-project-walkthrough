import XCTest
@testable import GorillaFlap

@MainActor
final class HighScoresTests: XCTestCase {

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: "gf.highScores")
    }

    func testIgnoresZeroScores() {
        let store = HighScores.shared
        store.clearForTesting()
        XCTAssertNil(store.record(score: 0))
        XCTAssertTrue(store.entries.isEmpty)
    }

    func testKeepsTopFiveSortedDescending() {
        let store = HighScores.shared
        store.clearForTesting()
        for value in [5, 20, 1, 12, 8, 30, 3] {
            store.record(score: value)
        }
        let scores = store.entries.map(\.score)
        XCTAssertEqual(scores, [30, 20, 12, 8, 5])
        XCTAssertEqual(store.entries.count, 5)
    }

    func testReturnsRankWhenPlaced() {
        let store = HighScores.shared
        store.clearForTesting()
        store.record(score: 10)
        let rank = store.record(score: 25)   // should be new #1
        XCTAssertEqual(rank, 1)
    }
}
