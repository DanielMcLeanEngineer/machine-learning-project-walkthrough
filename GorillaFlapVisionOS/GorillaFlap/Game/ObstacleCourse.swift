import RealityKit
import UIKit
import simd

/// Owns the recyclable pool of obstacle "windows" and the collision/scoring checks.
///
/// Course coordinates: the player advances along +z (`forwardDistance`). Each obstacle
/// sits at a fixed course-z and a random gap-center altitude. Obstacle entities live
/// under a `worldRoot` that the game loop slides to simulate player motion, so the
/// player themselves never has to physically walk.
@MainActor
final class ObstacleCourse {

    final class Obstacle {
        let entity: Entity
        let coin: Entity
        var z: Float = 0
        var gapCenter: Float = 0
        var gapHalf: Float = GameConfig.gapHalfHeight
        var scored = false
        var hasCoin = false
        var coinTaken = false
        init(entity: Entity, coin: Entity) {
            self.entity = entity
            self.coin = coin
        }
    }

    private(set) var obstacles: [Obstacle] = []
    private let worldRoot: Entity
    private var nextSpawnZ: Float = 0

    init(worldRoot: Entity) {
        self.worldRoot = worldRoot
    }

    func build() {
        worldRoot.addChild(AssetFactory.makeFloorGuide())

        nextSpawnZ = GameConfig.startRunway
        for _ in 0..<GameConfig.obstaclePoolSize {
            let entity = AssetFactory.makeObstacle()
            let coin = AssetFactory.makeCoin()
            entity.addChild(coin)
            let obstacle = Obstacle(entity: entity, coin: coin)
            worldRoot.addChild(entity)
            place(obstacle, atZ: nextSpawnZ, score: 0)
            nextSpawnZ += GameConfig.obstacleSpacing
            obstacles.append(obstacle)
        }
        refreshNextTarget(playerDistance: 0)
    }

    func reset() {
        nextSpawnZ = GameConfig.startRunway
        for obstacle in obstacles {
            place(obstacle, atZ: nextSpawnZ, score: 0)
            nextSpawnZ += GameConfig.obstacleSpacing
        }
        refreshNextTarget(playerDistance: 0)
    }

    private func place(_ obstacle: Obstacle, atZ z: Float, score: Int) {
        obstacle.z = z
        obstacle.gapCenter = Float.random(in: GameConfig.gapCenterRange)
        obstacle.gapHalf = GameConfig.gapHalf(forScore: score)
        obstacle.scored = false
        // Local position; worldRoot handles the player-relative offset each frame.
        obstacle.entity.position = [0, obstacle.gapCenter, -z]
        AssetFactory.setGap(obstacle.entity, halfHeight: obstacle.gapHalf)
        AssetFactory.setWallTint(obstacle.entity, Self.wallTint(forScore: score))
        AssetFactory.setHighlighted(obstacle.entity, false)

        // Some gaps carry a bonus coin in their center.
        obstacle.hasCoin = Float.random(in: 0...1) < GameConfig.coinSpawnChance
        obstacle.coinTaken = false
        obstacle.coin.isEnabled = obstacle.hasCoin
        obstacle.coin.position = .zero   // gap center, since the coin is a child of the obstacle
    }

    /// Move obstacles the player has passed back out to the front, scaling difficulty
    /// to the current score.
    func recycle(playerDistance: Float, score: Int) {
        for obstacle in obstacles where obstacle.z < playerDistance - GameConfig.recycleBehind {
            place(obstacle, atZ: nextSpawnZ, score: score)
            nextSpawnZ += GameConfig.obstacleSpacing
        }
    }

    /// Idle animation: spin any enabled coins a little each frame.
    func animate(deltaTime: Float) {
        for obstacle in obstacles where obstacle.hasCoin && !obstacle.coinTaken {
            obstacle.coin.orientation *= simd_quatf(angle: 2.5 * deltaTime, axis: [0, 1, 0])
        }
    }

    /// Result of advancing the player one frame against the obstacle field.
    /// `scored` carries 0 (dead center) … 1 (just barely fit) for combo scoring;
    /// `crashed` carries the gap center so practice mode can snap the player into it.
    enum Crossing { case none, scored(centerOffset: Float), crashed(gapCenter: Float) }

    /// Detect plane crossings between last frame and this frame. Returns whether the
    /// player just cleared a gap (+score) or hit a wall (game over).
    func evaluate(previousDistance: Float, currentDistance: Float, altitude: Float) -> Crossing {
        var result: Crossing = .none
        for obstacle in obstacles where !obstacle.scored {
            if previousDistance < obstacle.z && currentDistance >= obstacle.z {
                obstacle.scored = true
                let fitsTolerance = obstacle.gapHalf - GameConfig.playerRadius
                let offset = abs(altitude - obstacle.gapCenter)
                if GameConfig.fits(altitude: altitude, gapCenter: obstacle.gapCenter, gapHalf: obstacle.gapHalf) {
                    result = .scored(centerOffset: min(1, offset / max(0.0001, fitsTolerance)))
                } else {
                    return .crashed(gapCenter: obstacle.gapCenter)
                }
            }
        }
        return result
    }

    /// Collect any coin whose plane the player crosses while close to its center.
    /// Returns the number of coins grabbed this frame.
    func collectCoins(previousDistance: Float, currentDistance: Float, altitude: Float) -> Int {
        var grabbed = 0
        for obstacle in obstacles where obstacle.hasCoin && !obstacle.coinTaken {
            if previousDistance < obstacle.z && currentDistance >= obstacle.z,
               abs(altitude - obstacle.gapCenter) <= GameConfig.coinGrabRadius {
                obstacle.coinTaken = true
                obstacle.coin.isEnabled = false
                grabbed += 1
            }
        }
        return grabbed
    }

    /// Altitude of the nearest not-yet-cleared obstacle — feeds the HUD target marker.
    func nextGapCenter(playerDistance: Float) -> Float? {
        nextObstacle(playerDistance: playerDistance)?.gapCenter
    }

    /// Gap half-height of the nearest not-yet-cleared obstacle — sizes the HUD band.
    func nextGapHalf(playerDistance: Float) -> Float? {
        nextObstacle(playerDistance: playerDistance)?.gapHalf
    }

    func refreshNextTarget(playerDistance: Float) {
        let target = nextObstacle(playerDistance: playerDistance)
        for obstacle in obstacles {
            AssetFactory.setHighlighted(obstacle.entity, obstacle === target)
        }
    }

    private func nextObstacle(playerDistance: Float) -> Obstacle? {
        obstacles
            .filter { !$0.scored && $0.z >= playerDistance }
            .min { $0.z < $1.z }
    }

    /// Walls cool white at the start and warm toward red as difficulty climbs.
    private static func wallTint(forScore score: Int) -> UIColor {
        let t = CGFloat(min(Float(score) / GameConfig.speedRampByScore, 1))
        return UIColor(
            red: 0.85,
            green: 0.85 - 0.45 * t,
            blue: 0.85 - 0.55 * t,
            alpha: 1.0
        )
    }
}
