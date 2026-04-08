import SwiftUI

extension Color {
    static func dynamic(light: Color, dark: Color) -> Color {
        Color(uiColor: UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }
}

struct TPDesign {
    // MARK: - Divine Palette (Obsidian & Alabaster)
    static let obsidian = Color.dynamic(
        light: Color(red: 0.08, green: 0.08, blue: 0.09), // Stone obsidian
        dark: Color(red: 0.96, green: 0.96, blue: 0.98)  // Soft light text
    )
    static let isabelline = Color.dynamic(
        light: Color(red: 0.98, green: 0.98, blue: 0.96), // Warm paper
        dark: Color(red: 0.04, green: 0.04, blue: 0.05)  // Deep midnight background
    )
    static let alabaster = Color.dynamic(
        light: Color(red: 0.96, green: 0.96, blue: 0.94), // Soft ceramic
        dark: Color(red: 0.12, green: 0.12, blue: 0.14)  // Card/Surface obsidian
    )

    static let primary = obsidian
    static let secondary = Color.dynamic(
        light: .white,
        dark: Color(white: 0.2)
    )
    
    /// Used for cards, search bars, and floating elements to replace hardcoded Color.white
    static let secondaryBackground = Color.dynamic(
        light: .white,
        dark: Color(white: 0.12)
    )

    // MARK: - Brand Identity (Celestial & Marine)
    static let celestialBlue = Color(red: 0.30, green: 0.65, blue: 0.96) // Clear bright sky blue
    static let marineDeep = Color(red: 0.10, green: 0.45, blue: 0.85)   // Bright deep ocean
    static let accent = celestialBlue
    static let background = isabelline

    // MARK: - Semantic Text Colors (International Standard)
    static let textPrimary = obsidian
    static let textSecondary = Color.dynamic(
        light: Color(white: 0.45),
        dark: Color(white: 0.65)
    )
    static let textTertiary = Color.dynamic(
        light: Color(white: 0.7),
        dark: Color(white: 0.4)
    )
    static let divider = Color.dynamic(
        light: Color(white: 0.88),
        dark: Color(white: 0.2)
    )

    // MARK: - Shadow Palette (Layered Depth)
    static let shadowUltraSoft = Color.dynamic(light: .black.opacity(0.04), dark: .clear)
    static let shadowSubtle = Color.dynamic(light: .black.opacity(0.08), dark: .black.opacity(0.3))
    static let shadowDeep = Color.dynamic(light: .black.opacity(0.12), dark: .black.opacity(0.5))

    // MARK: - Cinematic Warm Palette (Vibe Tokens)
    static let warmCream = Color.dynamic(
        light: Color(red: 0.99, green: 0.98, blue: 0.96),
        dark: Color(red: 0.08, green: 0.08, blue: 0.10) // Darker warm surface
    )
    static let warmSand = Color.dynamic(
        light: Color(red: 0.97, green: 0.95, blue: 0.91),
        dark: Color(red: 0.10, green: 0.10, blue: 0.12)
    )
    static let warmGold = Color(red: 0.82, green: 0.68, blue: 0.40)
    static let warmAmber = Color(red: 0.88, green: 0.60, blue: 0.25)
    static let deepNavy = Color(red: 0.04, green: 0.08, blue: 0.18)
    static let midnightTeal = Color(red: 0.04, green: 0.14, blue: 0.18)
    static let leicaRed = Color(red: 0.72, green: 0.11, blue: 0.11) // Iconic accent

    // MARK: - Grid & Scale
    static let anamorphicRatio: CGFloat = 2.35 / 1.0
    static let spacing2: CGFloat = 2
    static let spacing4: CGFloat = 4
    static let spacing8: CGFloat = 8
    static let spacing12: CGFloat = 12
    static let spacing16: CGFloat = 16
    static let spacing20: CGFloat = 20
    static let spacing24: CGFloat = 24
    static let spacing32: CGFloat = 32
    static let spacing48: CGFloat = 48

    static let radiusSmall: CGFloat = 10
    static let radiusMedium: CGFloat = 18
    static let radiusLarge: CGFloat = 28
    static let radiusXL: CGFloat = 40

    // MARK: - Transitions (Liquid Gradient)
    static let backgroundGradient = LinearGradient(
        colors: [warmCream, isabelline],
        startPoint: .top,
        endPoint: .bottom
    )

    static let cinematicGradient = LinearGradient(
        colors: [deepNavy, obsidian],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let accentGradient = LinearGradient(
        colors: [celestialBlue, marineDeep],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let brandGradient = LinearGradient(
        colors: [Color(red: 0.45, green: 0.75, blue: 0.98), Color(red: 0.15, green: 0.55, blue: 0.92)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let celestialGlow = celestialBlue

    static let heroGradient = brandGradient


    static let warmAccentGradient = LinearGradient(
        colors: [warmGold, warmAmber],
        startPoint: .leading,
        endPoint: .trailing
    )

    // MARK: - Typography (Editorial Architecture)
    
    /// The 'Journal' header. Use for discovery and main section titles to evoke high-end print media.
    static func editorialSerif(_ size: CGFloat = 34) -> Font {
        .system(size: size, weight: .bold, design: .serif)
    }

    static func titleFont(_ size: CGFloat = 32, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    static func cinematicTitle(_ size: CGFloat = 40) -> Font {
        .system(size: size, weight: .black, design: .default)
    }

    static func bodyFont(_ size: CGFloat = 16, weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    static func overline() -> Font {
        .system(size: 11, weight: .bold, design: .rounded)
    }

    static func captionFont() -> Font {
        .system(size: 12, weight: .semibold)
    }
    
    static func cardTitle() -> Font {
        .system(size: 18, weight: .bold, design: .rounded)
    }

    // MARK: - Luxury Motion (Weighted Transitions)
    
    /// Deliberate, premium-weighted movement (cubic-bezier equivalent in SwiftUI)
    static let luxurySpring = Animation.interpolatingSpring(stiffness: 120, damping: 20)
    static let softSnap = Animation.spring(response: 0.4, dampingFraction: 0.9)
    static let cinemaReveal = Animation.timingCurve(0.2, 0.8, 0.2, 1.0, duration: 0.8)
    
    static let springDefault = Animation.spring(response: 0.4, dampingFraction: 0.8)
    static let springBouncy = Animation.spring(response: 0.5, dampingFraction: 0.65)
    static let springGentle = Animation.spring(response: 0.6, dampingFraction: 0.85)

    static let shimmerAnimation = Animation.linear(duration: 2.5).repeatForever(autoreverses: false)
}


// MARK: - Liquid Shimmer Effect (iOS 26 Premium)

struct LiquidShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    ZStack {
                        // High-performance sweeping light
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    stops: [
                                        .init(color: .clear, location: 0),
                                        .init(color: .white.opacity(0.12), location: 0.48),
                                        .init(color: .white.opacity(0.35), location: 0.5),
                                        .init(color: .white.opacity(0.12), location: 0.52),
                                        .init(color: .clear, location: 1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: geo.size.width * 1.5)
                            .rotationEffect(.degrees(30))
                            .offset(x: -geo.size.width + (geo.size.width * 2 * phase))
                    }
                }
                .mask(content)
            )
            .drawingGroup() // High performance rendering for gradients
            .onAppear {
                withAnimation(TPDesign.shimmerAnimation) {
                    phase = 1
                }
            }
    }
}

extension View {
    func liquidShimmer() -> some View {
        self.modifier(LiquidShimmerModifier())
    }
}

// MARK: - Common Premium Components

struct TravelingCountdown: View {
    let startDate: Date
    
    var daysUntil: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let start = calendar.startOfDay(for: startDate)
        let components = calendar.dateComponents([.day], from: today, to: start)
        return components.day ?? 0
    }

    var body: some View {
        if daysUntil >= 0 {
            HStack(spacing: 6) {
                Image(systemName: "timer")
                    .font(.system(size: 10, weight: .bold))
                Text(daysUntil == 0 ? "今天出发" : "距离出发还有 \(daysUntil) 天")
                    .font(TPDesign.overline())
                    .tracking(0.5)
            }
            .foregroundStyle(TPDesign.leicaRed.opacity(0.8))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(TPDesign.leicaRed.opacity(0.05))
            .clipShape(Capsule())
        }
    }
}

// MARK: - View Helpers for Tracking

extension View {
    func trackingMedium() -> some View { self.tracking(0.5) }
    func trackingWide() -> some View { self.tracking(2.0) }
}

// MARK: - Liquid Glass 3.0 (Razor Precision)

struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = TPDesign.radiusLarge
    var intensity: CGFloat = 0.5

    func body(content: Content) -> some View {
        content
            .padding()
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial.opacity(intensity))
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [TPDesign.celestialBlue.opacity(0.03), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [TPDesign.obsidian.opacity(0.2), TPDesign.obsidian.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            )

            .shadow(color: .black.opacity(0.02), radius: 1, x: 0, y: 1)
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
            .shadow(color: .black.opacity(0.06), radius: 20, x: 0, y: 10)
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = TPDesign.radiusLarge, intensity: CGFloat = 0.5) -> some View {
        self.modifier(GlassCardModifier(cornerRadius: cornerRadius, intensity: intensity))
    }
}

// MARK: - Shadow Architectures

struct ShadowModifier: ViewModifier {
    enum Size { case small, medium, large, floating }
    let size: Size

    func body(content: Content) -> some View {
        switch size {
        case .small:
            content.shadow(color: .black.opacity(0.04), radius: 3, x: 0, y: 2)
        case .medium:
            content
                .shadow(color: .black.opacity(0.03), radius: 2, x: 0, y: 1)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        case .large:
            content
                .shadow(color: .black.opacity(0.02), radius: 4, x: 0, y: 2)
                .shadow(color: .black.opacity(0.08), radius: 24, x: 0, y: 12)
        case .floating:
            content
                .shadow(color: .black.opacity(0.12), radius: 30, x: 0, y: 15)
                .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
        }
    }
}

extension View {
    func shadowSmall() -> some View { modifier(ShadowModifier(size: .small)) }
    func shadowMedium() -> some View { modifier(ShadowModifier(size: .medium)) }
    func shadowLarge() -> some View { modifier(ShadowModifier(size: .large)) }
    func shadowFloating() -> some View { modifier(ShadowModifier(size: .floating)) }

    func shadowGlow(color: Color, radius: CGFloat = 12) -> some View {
        shadow(color: color.opacity(0.2), radius: radius, x: 0, y: 4)
    }
}

// MARK: - Cinematic Master Controls

extension View {
    /// Simulates a soft film warmth without color shifting significantly
    func warmFilm(warmth: CGFloat = 0.05) -> some View {
        overlay(Color.orange.opacity(warmth).blendMode(.softLight).allowsHitTesting(false))
    }
    
    /// Professional fade-in with deliberate easing
    func cinematicFadeIn(delay: Double = 0.0) -> some View {
        self.modifier(CinematicFadeInModifier(delay: delay))
    }
}

struct CinematicFadeInModifier: ViewModifier {
    let delay: Double
    @State private var appear = false
    
    func body(content: Content) -> some View {
        content
            .opacity(appear ? 1 : 0)
            .offset(y: appear ? 0 : 8)
            .onAppear {
                withAnimation(TPDesign.cinemaReveal.delay(delay)) {
                    appear = true
                }
            }
    }
}

// MARK: - Tactical Haptics (Leica Touch)

struct TPHaptic {
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
    
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
    
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    /// Deliberate Leica-style shutter press feel
    static func mechanicalPress() {
        let generator = UIImpactFeedbackGenerator(style: .rigid)
        generator.impactOccurred(intensity: 0.8)
    }
}

// MARK: - Global Semantic Extensions

extension Color {
    static let tpAccent = TPDesign.accent
    static let tpSurface = TPDesign.alabaster

    static func statusColor(for status: TravelStatus) -> Color {
        switch status {
        case .wishing: return Color(red: 0.38, green: 0.75, blue: 1.0)  // Sky blue — dreaming
        case .planning: return TPDesign.warmAmber                         // Warm amber — preparing
        case .traveling: return TPDesign.celestialBlue                      // Brand blue — in motion
        case .travelled: return Color(white: 0.55)                        // Warm gray — archived
        case .cancelled: return Color(red: 0.85, green: 0.35, blue: 0.35) // Muted red — released
        }
    }
}
