import SwiftUI

/// Pure SwiftUI confetti celebration animation.
/// Overlays a burst of colorful particles that expand outward and fade.
struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    @State private var isActive = false

    private let colors: [Color] = [
        TPDesign.celestialBlue,
        TPDesign.warmAmber,
        TPDesign.warmGold,
        TPDesign.marineDeep,
        .green,
        .orange,
        .pink
    ]

    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .scaleEffect(isActive ? 1 : 0)
                    .offset(
                        x: isActive ? particle.offsetX : 0,
                        y: isActive ? particle.offsetY : 0
                    )
                    .rotationEffect(.degrees(isActive ? particle.rotation : 0))
                    .opacity(isActive ? 0 : 1)
            }
        }
        .onAppear {
            generateParticles()
            withAnimation(.easeOut(duration: 1.5)) {
                isActive = true
            }
        }
    }

    private func generateParticles() {
        let count = 50
        particles = (0..<count).map { _ in
            ConfettiParticle(
                color: colors.randomElement() ?? .blue,
                size: CGFloat.random(in: 4...10),
                offsetX: CGFloat.random(in: -200...200),
                offsetY: CGFloat.random(in: -350...50),
                rotation: Double.random(in: 0...720)
            )
        }
    }
}

private struct ConfettiParticle: Identifiable {
    let id = UUID()
    let color: Color
    let size: CGFloat
    let offsetX: CGFloat
    let offsetY: CGFloat
    let rotation: Double
}
