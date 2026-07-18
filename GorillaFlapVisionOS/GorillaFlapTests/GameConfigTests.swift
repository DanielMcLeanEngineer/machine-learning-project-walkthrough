import XCTest
@testable import GorillaFlap

final class GameConfigTests: XCTestCase {

    func testGapTightensWithScore() {
        // At score 0 the gap is the easy default; at/after the tighten score it's minimal.
        XCTAssertEqual(GameConfig.gapHalf(forScore: 0), GameConfig.gapHalfHeight, accuracy: 0.0001)
        XCTAssertEqual(GameConfig.gapHalf(forScore: 1000), GameConfig.gapHalfHeightMin, accuracy: 0.0001)
    }

    func testGapIsMonotonicallyNonIncreasing() {
        var previous = GameConfig.gapHalf(forScore: 0)
        for score in stride(from: 0, through: 40, by: 2) {
            let current = GameConfig.gapHalf(forScore: score)
            XCTAssertLessThanOrEqual(current, previous + 0.0001, "gap should not grow as score rises")
            previous = current
        }
    }

    func testForwardSpeedRampsAndClamps() {
        XCTAssertEqual(GameConfig.forwardBaseSpeed(forScore: 0), GameConfig.baseForwardSpeed, accuracy: 0.0001)
        let top = GameConfig.forwardBaseSpeed(forScore: 10_000)
        XCTAssertEqual(top, GameConfig.baseForwardSpeed + GameConfig.maxDifficultySpeedBonus, accuracy: 0.0001)
        // Never exceeds the clamped maximum.
        XCTAssertLessThanOrEqual(GameConfig.forwardBaseSpeed(forScore: 5), top + 0.0001)
    }

    func testFitsPredicate() {
        let center: Float = 1.5
        let half: Float = 0.6
        // Dead center always fits.
        XCTAssertTrue(GameConfig.fits(altitude: center, gapCenter: center, gapHalf: half))
        // Just inside the tolerance fits; just outside does not.
        let tolerance = half - GameConfig.playerRadius
        XCTAssertTrue(GameConfig.fits(altitude: center + tolerance - 0.01, gapCenter: center, gapHalf: half))
        XCTAssertFalse(GameConfig.fits(altitude: center + tolerance + 0.01, gapCenter: center, gapHalf: half))
    }

    func testTighterGapIsHarderToFit() {
        // A wide gap admits an offset that a tight gap rejects.
        let offset: Float = 0.3
        XCTAssertTrue(GameConfig.fits(altitude: 1.5 + offset, gapCenter: 1.5, gapHalf: 0.6))
        XCTAssertFalse(GameConfig.fits(altitude: 1.5 + offset, gapCenter: 1.5, gapHalf: 0.4))
    }
}
