import SwiftUI

// MARK: - Focus Pull Transition

extension View {
    func focusPullTransition() -> some View {
        self.transition(.asymmetric(
            insertion: .modifier(
                active: FocusPullModifier(blur: 20, scale: 0.9, opacity: 0),
                identity: FocusPullModifier(blur: 0, scale: 1.0, opacity: 1)
            ),
            removal: .modifier(
                active: FocusPullModifier(blur: 20, scale: 1.1, opacity: 0),
                identity: FocusPullModifier(blur: 0, scale: 1.0, opacity: 1)
            )
        ))
    }
}

// MARK: - Shimmer Effect (Centralized)

extension View {
    func shimmer() -> some View {
        self.modifier(ShimmerModifier())
    }
}

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { geo in
                    LinearGradient(
                        colors: [
                            .white.opacity(0.0),
                            .white.opacity(0.15),
                            .white.opacity(0.0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 2)
                    .offset(x: phase * geo.size.width)
                }
                .clipped()
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

// MARK: - Pulse Glow

extension View {
    func pulseGlow(color: Color = .tpAccent, radius: CGFloat = 12) -> some View {
        self.modifier(PulseGlowModifier(color: color, glowRadius: radius))
    }
}

struct PulseGlowModifier: ViewModifier {
    let color: Color
    let glowRadius: CGFloat
    @State private var glowing = false

    func body(content: Content) -> some View {
        content
            .shadow(color: glowing ? color.opacity(0.4) : color.opacity(0.1), radius: glowing ? glowRadius : 4)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    glowing = true
                }
            }
    }
}

// MARK: - Parallax Scroll

extension View {
    func parallaxScroll(height: CGFloat) -> some View {
        self.modifier(ParallaxScrollModifier(height: height))
    }
}

struct ParallaxScrollModifier: ViewModifier {
    let height: CGFloat

    func body(content: Content) -> some View {
        GeometryReader { geo in
            let offset = geo.frame(in: .global).minY
            content
                .offset(y: offset > 0 ? -offset * 0.4 : 0)
                .scaleEffect(offset > 0 ? 1 + (offset * 0.001) : 1)
                .frame(height: height + (offset > 0 ? offset : 0))
        }
        .frame(height: height)
        .clipped()
    }
}

// MARK: - Existing Internal Modifiers

struct FocusPullModifier: ViewModifier {
    let blur: CGFloat
    let scale: CGFloat
    let opacity: Double

    func body(content: Content) -> some View {
        content
            .blur(radius: blur)
            .scaleEffect(scale)
            .opacity(opacity)
    }
}

struct FilmGrainModifier: ViewModifier {
    let intensity: Float

    func body(content: Content) -> some View {
        content
            .overlay {
                // Safe fallback: Static subtle noise texture or just skip if shader fails
                Color.black.opacity(Double(intensity) * 0.2)
                    .blendMode(.multiply)
                    .allowsHitTesting(false)
            }
    }
}

extension View {
    func filmGrain(intensity: Float = 0.05) -> some View {
        self.modifier(FilmGrainModifier(intensity: intensity))
    }
}
