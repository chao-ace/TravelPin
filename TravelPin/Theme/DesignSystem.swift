import SwiftUI

struct TPDesign {
    // Colors
    static let primary = Color.black
    static let secondary = Color.white
    static let accent = Color(red: 0.1, green: 0.4, blue: 0.9)
    static let background = Color(white: 0.97)
    
    // Anamorphic Constants
    static let anamorphicRatio: CGFloat = 2.35 / 1.0
    
    // Glassmorphism
    static var glassEffect: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(.white.opacity(0.4), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
    
    // Typography
    static func titleFont(_ size: CGFloat = 32) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }
    
    static func cinematicTitle(_ size: CGFloat = 40) -> Font {
        .system(size: size, weight: .black, design: .default)
    }
    
    static func bodyFont(_ size: CGFloat = 16) -> Font {
        .system(size: size, weight: .medium, design: .default)
    }
}

struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 24
    
    func body(content: Content) -> some View {
        content
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(.white.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 15, x: 0, y: 10)
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 24) -> some View {
        self.modifier(GlassCardModifier(cornerRadius: cornerRadius))
    }
}

extension Color {
    static let tpAccent = Color(red: 0.1, green: 0.4, blue: 0.9)
    static let tpSurface = Color(white: 0.98)

    static func statusColor(for status: TravelStatus) -> Color {
        switch status {
        case .wishing: return .blue
        case .planning: return .orange
        case .traveling: return .green
        case .travelled: return .secondary
        case .cancelled: return .red
        }
    }
}
