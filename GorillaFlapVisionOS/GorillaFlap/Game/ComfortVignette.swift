import RealityKit
import UIKit

/// A head-locked peripheral dimmer that fades in during fast forward/vertical motion to
/// reduce vection discomfort — the standard VR comfort trick, kept subtle and optional.
///
/// The radial gradient texture is generated at runtime (clear center → black edge), so
/// there are still no image assets in the project. Intensity is driven each frame by the
/// game loop via `OpacityComponent`.
enum ComfortVignette {

    /// Build the vignette entity. Returns a plain (invisible) entity if texture creation
    /// fails for any reason, so the caller never has to special-case it.
    @MainActor
    static func make() async -> Entity {
        let entity = Entity()
        guard let texture = await radialTexture() else {
            entity.components.set(OpacityComponent(opacity: 0))
            return entity
        }

        var material = UnlitMaterial()
        material.color = .init(tint: .white, texture: .init(texture))
        material.blending = .transparent(opacity: 1.0)

        // Large plane placed close to the eyes so it fills the periphery.
        let mesh = MeshResource.generatePlane(width: 3.0, height: 3.0)
        let model = ModelEntity(mesh: mesh, materials: [material])
        entity.addChild(model)
        entity.position = [0, 0, -0.6]
        entity.components.set(OpacityComponent(opacity: 0))
        return entity
    }

    private static func radialTexture() async -> TextureResource? {
        let size = 512
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        let image = renderer.image { ctx in
            let colors = [
                UIColor.black.withAlphaComponent(0).cgColor,
                UIColor.black.withAlphaComponent(0).cgColor,
                UIColor.black.withAlphaComponent(1).cgColor
            ]
            let locations: [CGFloat] = [0.0, 0.58, 1.0]
            guard let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors as CFArray,
                locations: locations
            ) else { return }
            let center = CGPoint(x: size / 2, y: size / 2)
            ctx.cgContext.drawRadialGradient(
                gradient,
                startCenter: center, startRadius: 0,
                endCenter: center, endRadius: CGFloat(size) / 2,
                options: [.drawsAfterEndLocation]
            )
        }
        guard let cg = image.cgImage else { return nil }
        return try? await TextureResource(image: cg, options: .init(semantic: .color))
    }
}
