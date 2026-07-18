import RealityKit
import UIKit
import simd

/// Builds every visual in the game from RealityKit primitives. Deliberately simple:
/// boxes and a few emissive accents. No imported meshes, textures, or USDZ files.
enum AssetFactory {

    // Unlit so the course reads consistently in full immersion without scene lighting.
    static let wallColor = UnlitMaterial(color: .init(white: 0.82, alpha: 1.0))
    static let gapAccentColor = UnlitMaterial(color: .init(red: 0.20, green: 0.95, blue: 0.70, alpha: 1.0))
    static let nextGapAccentColor = UnlitMaterial(color: .init(red: 1.0, green: 0.78, blue: 0.20, alpha: 1.0))
    static let coinColor = UnlitMaterial(color: .init(red: 1.0, green: 0.85, blue: 0.25, alpha: 1.0))

    private static let wallHeight: Float = 12.0

    /// A "window" obstacle: a wall above and below a gap, framed by an emissive ring so
    /// the player can read the gap's height from far away.
    ///
    /// The prefab is centered on the gap (local y = 0 is the gap center). Both the gap
    /// *size* and the whole entity's position can be changed at recycle time without any
    /// remeshing — walls only move, and the frame's vertical bars are scaled.
    static func makeObstacle() -> Entity {
        let root = Entity()

        let wallWidth: Float = 9.0
        let wallDepth: Float = 0.4
        let wallMesh = MeshResource.generateBox(width: wallWidth, height: wallHeight, depth: wallDepth)

        let bottom = ModelEntity(mesh: wallMesh, materials: [wallColor])
        root.addChild(bottom)
        let top = ModelEntity(mesh: wallMesh, materials: [wallColor])
        root.addChild(top)

        // Emissive frame around the opening — the "aim here" cue.
        let frame = Entity()
        let thickness: Float = 0.06
        let depth: Float = 0.5
        let width: Float = 1.8
        let halfWidth = width / 2

        let horizontal = MeshResource.generateBox(width: width + thickness, height: thickness, depth: depth)
        // Built at unit height so it can be scaled to any gap size without remeshing.
        let vertical = MeshResource.generateBox(width: thickness, height: 1.0, depth: depth)

        let topBar = ModelEntity(mesh: horizontal, materials: [gapAccentColor])
        let bottomBar = ModelEntity(mesh: horizontal, materials: [gapAccentColor])
        let leftBar = ModelEntity(mesh: vertical, materials: [gapAccentColor]); leftBar.position.x = -halfWidth
        let rightBar = ModelEntity(mesh: vertical, materials: [gapAccentColor]); rightBar.position.x = halfWidth
        for bar in [topBar, bottomBar, leftBar, rightBar] { frame.addChild(bar) }
        root.addChild(frame)

        root.components.set(ObstacleParts(
            topWall: top, bottomWall: bottom, frame: frame,
            topBar: topBar, bottomBar: bottomBar, leftBar: leftBar, rightBar: rightBar
        ))

        setGap(root, halfHeight: GameConfig.gapHalfHeight)
        return root
    }

    /// Reshape an obstacle's opening to a new half-height (walls move, vertical bars scale).
    static func setGap(_ obstacle: Entity, halfHeight half: Float) {
        guard let p = obstacle.components[ObstacleParts.self] else { return }
        p.bottomWall?.position.y = -(half + wallHeight / 2)
        p.topWall?.position.y = (half + wallHeight / 2)
        p.topBar?.position.y = half
        p.bottomBar?.position.y = -half
        p.leftBar?.scale.y = 2 * half
        p.rightBar?.scale.y = 2 * half
    }

    /// Tint an obstacle's walls — used to warm their color as difficulty climbs.
    static func setWallTint(_ obstacle: Entity, _ color: UIColor) {
        guard let p = obstacle.components[ObstacleParts.self] else { return }
        let material = UnlitMaterial(color: color)
        (p.topWall as? ModelEntity)?.model?.materials = [material]
        (p.bottomWall as? ModelEntity)?.model?.materials = [material]
    }

    /// Toggle the frame between the normal accent and the "next target" highlight.
    static func setHighlighted(_ obstacle: Entity, _ highlighted: Bool) {
        guard let frame = obstacle.components[ObstacleParts.self]?.frame else { return }
        let material = highlighted ? nextGapAccentColor : gapAccentColor
        for case let bar as ModelEntity in frame.children {
            bar.model?.materials = [material]
        }
    }

    /// A spinning collectible coin placed in the center of some gaps for bonus points.
    static func makeCoin() -> Entity {
        let mesh = MeshResource.generateBox(width: 0.28, height: 0.28, depth: 0.04, cornerRadius: 0.02)
        let coin = ModelEntity(mesh: mesh, materials: [coinColor])
        coin.components.set(SpinComponent())
        return coin
    }

    /// A faint ground grid so forward motion is legible (helps comfort) without
    /// occluding the real room too much.
    static func makeFloorGuide() -> Entity {
        let root = Entity()
        let material = UnlitMaterial(color: .init(white: 0.4, alpha: 0.35))
        let lineMesh = MeshResource.generateBox(width: 0.03, height: 0.001, depth: 200)

        for i in -4...4 {
            let line = ModelEntity(mesh: lineMesh, materials: [material])
            line.position = [Float(i) * 1.0, -0.001, 0]
            root.addChild(line)
        }
        return root
    }
}

/// Weak references to an obstacle's reshapeable parts, so the course can resize and
/// recolor it at recycle time.
struct ObstacleParts: Component {
    weak var topWall: Entity?
    weak var bottomWall: Entity?
    weak var frame: Entity?
    weak var topBar: Entity?
    weak var bottomBar: Entity?
    weak var leftBar: Entity?
    weak var rightBar: Entity?
}

/// Marks an entity that should slowly spin (coins), animated by the game loop.
struct SpinComponent: Component {}
