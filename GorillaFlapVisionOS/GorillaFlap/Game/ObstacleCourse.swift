import RealityKit
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
        var z: Float = 0
        var gapCenter: Float = 0
        var scored = false
        init(entity: Entity) { self.entity = entity }
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
            let obstacle = Obstacle(entity: AssetFactory.makeObstacle())
            worldRoot.addChild(obstacle.entity)
            place(obstacle, atZ: nextSpawnZ)
            nextSpawnZ += GameConfig.obstacleSpacing
            obstacles.append(obstacle)
        }
        refreshNextTarget(playerDistance: 0)
    }

    func reset() {
        nextSpawnZ = GameConfig.startRunway
        for obstacle in obstacles {
            place(obstacle, atZ: nextSpawnZ)
            nextSpawnZ += GameConfig.obstacleSpacing
        }
        refreshNextTarget(playerDistance: 0)
    }

    private func place(_ obstacle: Obstacle, atZ z: Float) {
        obstacle.z = z
        obstacle.gapCenter = Float.random(in: GameConfig.gapCenterRange)
        obstacle.scored = false
        // Local position; worldRoot handles the player-relative offset each frame.
        obstacle.entity.position = [0, obstacle.gapCenter, -z]
        setFrameHighlighted(obstacle, false)
    }

    /// Move obstacles that the player has passed back out to the front of the course.
    func recycle(playerDistance: Float) {
        for obstacle in obstacles where obstacle.z < playerDistance - GameConfig.recycleBehind {
            place(obstacle, atZ: nextSpawnZ)
            nextSpawnZ += GameConfig.obstacleSpacing
        }
    }

    /// Result of advancing the player one frame against the obstacle field.
    enum Crossing { case none, scored, crashed }

    /// Detect plane crossings between last frame and this frame. Returns whether the
    /// player just cleared a gap (+score) or hit a wall (game over).
    func evaluate(previousDistance: Float, currentDistance: Float, altitude: Float) -> Crossing {
        var result: Crossing = .none
        for obstacle in obstacles where !obstacle.scored {
            if previousDistance < obstacle.z && currentDistance >= obstacle.z {
                obstacle.scored = true
                let fitsTolerance = GameConfig.gapHalfHeight - GameConfig.playerRadius
                if abs(altitude - obstacle.gapCenter) <= fitsTolerance {
                    result = .scored
                } else {
                    return .crashed
                }
            }
        }
        return result
    }

    /// Altitude of the nearest not-yet-cleared obstacle — feeds the HUD target marker.
    func nextGapCenter(playerDistance: Float) -> Float? {
        obstacles
            .filter { !$0.scored && $0.z >= playerDistance }
            .min { $0.z < $1.z }?
            .gapCenter
    }

    func refreshNextTarget(playerDistance: Float) {
        let target = obstacles
            .filter { !$0.scored && $0.z >= playerDistance }
            .min { $0.z < $1.z }
        for obstacle in obstacles {
            setFrameHighlighted(obstacle, obstacle === target)
        }
    }

    private func setFrameHighlighted(_ obstacle: Obstacle, _ highlighted: Bool) {
        guard let frame = obstacle.entity.components[GapFrameComponent.self]?.frame else { return }
        let material = highlighted ? AssetFactory.nextGapAccentColor : AssetFactory.gapAccentColor
        frame.children.forEach { child in
            (child as? ModelEntity)?.model?.materials = [material]
        }
    }
}
