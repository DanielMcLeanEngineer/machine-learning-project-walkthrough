import RealityKit
import UIKit

/// A large inward-facing gradient dome so the fully-immersive space reads as a calm sky
/// rather than a black void. The gradient also gives a faint horizon reference, which
/// helps with spatial comfort. Texture is generated at runtime — no image assets.
enum Skybox {

    @MainActor
    static func make() async -> Entity {
        let sphere = MeshResource.generateSphere(radius: 60)
        var material = UnlitMaterial(color: .init(white: 0.1, alpha: 1))
        if let texture = await gradientTexture() {
            material.color = .init(tint: .white, texture: .init(texture))
        }
        let dome = ModelEntity(mesh: sphere, materials: [material])
        // Flip the sphere inside-out so we see its interior surface.
        dome.scale = [-1, 1, 1]
        return dome
    }

    private static func gradientTexture() async -> TextureResource? {
        let w = 16
        let h = 512
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: w, height: h))
        let image = renderer.image { ctx in
            let colors = [
                UIColor(red: 0.03, green: 0.06, blue: 0.10, alpha: 1).cgColor,  // zenith
                UIColor(red: 0.07, green: 0.16, blue: 0.20, alpha: 1).cgColor,  // mid
                UIColor(red: 0.11, green: 0.30, blue: 0.30, alpha: 1).cgColor   // horizon
            ]
            guard let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors as CFArray,
                locations: [0.0, 0.55, 1.0]
            ) else { return }
            ctx.cgContext.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: 0, y: h),
                options: []
            )
        }
        guard let cg = image.cgImage else { return nil }
        return try? await TextureResource(image: cg, options: .init(semantic: .color))
    }
}
