import RealityKit
import simd

/// Builds every visual in the game from RealityKit primitives. Deliberately simple:
/// boxes and a few emissive accents. No imported meshes, textures, or USDZ files.
enum AssetFactory {

    // A small, friendly palette so the world reads clearly against the passthrough.
    static let wallColor = SimpleMaterial(color: .init(white: 0.85, alpha: 1.0), roughness: 0.9, isMetallic: false)
    static let gapAccentColor = UnlitMaterial(color: .init(red: 0.20, green: 0.95, blue: 0.70, alpha: 1.0))
    static let nextGapAccentColor = UnlitMaterial(color: .init(red: 1.0, green: 0.78, blue: 0.20, alpha: 1.0))

    /// A rigid "window" obstacle: a wall above and below a fixed-size gap, framed by
    /// an emissive ring so the player can read the gap's height from far away.
    ///
    /// The prefab is centered on the gap (local y = 0 is the gap center), so recycling
    /// is just a matter of moving the whole entity — no remeshing required.
    static func makeObstacle() -> Entity {
        let root = Entity()

        let gapHalf = GameConfig.gapHalfHeight
        let wallHeight: Float = 12.0
        let wallWidth: Float = 9.0
        let wallDepth: Float = 0.4

        let wallMesh = MeshResource.generateBox(width: wallWidth, height: wallHeight, depth: wallDepth)

        let bottom = ModelEntity(mesh: wallMesh, materials: [wallColor])
        bottom.position.y = -(gapHalf + wallHeight / 2)
        root.addChild(bottom)

        let top = ModelEntity(mesh: wallMesh, materials: [wallColor])
        top.position.y = (gapHalf + wallHeight / 2)
        root.addChild(top)

        // Emissive frame hugging the gap opening — the visual cue for "aim here".
        let frame = makeGapFrame(halfHeight: gapHalf, width: 1.8, material: gapAccentColor)
        root.addChild(frame)
        root.components.set(GapFrameComponent(frame: frame))

        return root
    }

    /// Four thin emissive bars outlining the rectangular opening.
    private static func makeGapFrame(halfHeight: Float, width: Float, material: UnlitMaterial) -> Entity {
        let frame = Entity()
        let thickness: Float = 0.06
        let depth: Float = 0.5
        let halfWidth = width / 2

        let horizontal = MeshResource.generateBox(width: width + thickness, height: thickness, depth: depth)
        let vertical = MeshResource.generateBox(width: thickness, height: 2 * halfHeight, depth: depth)

        let topBar = ModelEntity(mesh: horizontal, materials: [material]); topBar.position.y = halfHeight
        let bottomBar = ModelEntity(mesh: horizontal, materials: [material]); bottomBar.position.y = -halfHeight
        let leftBar = ModelEntity(mesh: vertical, materials: [material]); leftBar.position.x = -halfWidth
        let rightBar = ModelEntity(mesh: vertical, materials: [material]); rightBar.position.x = halfWidth

        for bar in [topBar, bottomBar, leftBar, rightBar] { frame.addChild(bar) }
        return frame
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

/// Lets the obstacle manager recolor a gap frame to flag the *next* obstacle to clear.
struct GapFrameComponent: Component {
    weak var frame: Entity?
}
