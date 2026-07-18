import XCTest
@testable import GorillaFlap

@MainActor
final class GameSettingsTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Start each test from a clean slate.
        for key in ["gf.swingSensitivity", "gf.liftStrength", "gf.floatiness",
                    "gf.comfortVignette", "gf.practiceMode"] {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    func testDefaultsAreSane() {
        let s = GameSettings()
        XCTAssertEqual(s.swingSensitivity, GameSettings.defaultSensitivity, accuracy: 0.0001)
        XCTAssertEqual(s.liftStrength, GameSettings.defaultLift, accuracy: 0.0001)
        XCTAssertFalse(s.practiceMode)
    }

    func testSensitivityMapsInverselyToThreshold() {
        let s = GameSettings()
        s.swingSensitivity = 0        // least sensitive → highest threshold
        let hard = s.swingSpeedThreshold
        s.swingSensitivity = 1        // most sensitive → lowest threshold
        let easy = s.swingSpeedThreshold
        XCTAssertGreaterThan(hard, easy)
        XCTAssertEqual(hard, 1.6, accuracy: 0.001)
        XCTAssertEqual(easy, 0.45, accuracy: 0.001)
    }

    func testFloatinessScalesGravity() {
        let s = GameSettings()
        s.floatiness = 0              // heavy → stronger pull (more negative)
        let heavy = s.effectiveGravity
        s.floatiness = 1              // floaty → weaker pull
        let floaty = s.effectiveGravity
        XCTAssertLessThan(heavy, floaty)      // heavier gravity is more negative
        XCTAssertLessThan(heavy, 0)
        XCTAssertLessThan(floaty, 0)
    }

    func testPersistenceRoundTrips() {
        let s1 = GameSettings()
        s1.liftStrength = 1.4
        s1.practiceMode = true
        // A fresh instance should read the persisted values.
        let s2 = GameSettings()
        XCTAssertEqual(s2.liftStrength, 1.4, accuracy: 0.0001)
        XCTAssertTrue(s2.practiceMode)
    }
}
