import SwiftUI

// MARK: - Cinematic Button Style (Premium Press Feedback)

struct CinematicButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(TPDesign.softSnap, value: configuration.isPressed)
    }
}

// MARK: - Primary Button (Gradient Filled)

struct CinematicPrimaryButton: View {
    let locKey: String
    let icon: String?
    let action: () -> Void
    var isLoading: Bool = false

    init(locKey: String, icon: String? = nil, isLoading: Bool = false, action: @escaping () -> Void) {
        self.locKey = locKey
        self.icon = icon
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                }
                Text(locKey: locKey)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(TPDesign.accentGradient)
            .clipShape(Capsule())
            .shadowLarge()
        }
        .disabled(isLoading)
        .buttonStyle(CinematicButtonStyle())
    }
}

// MARK: - Secondary Button (Outlined)

struct CinematicSecondaryButton: View {
    let locKey: String
    let icon: String?
    let action: () -> Void
    var isDestructive: Bool = false

    init(locKey: String, icon: String? = nil, isDestructive: Bool = false, action: @escaping () -> Void) {
        self.locKey = locKey
        self.icon = icon
        self.isDestructive = isDestructive
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                }
                Text(locKey: locKey)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(isDestructive ? .red : Color.tpAccent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isDestructive ? Color.red.opacity(0.08) : Color.clear)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isDestructive ? Color.red.opacity(0.3) : Color.tpAccent.opacity(0.3), lineWidth: 1.5)
            )
        }
        .buttonStyle(CinematicButtonStyle())
    }
}

// MARK: - Icon Button (Circular)

struct CinematicIconButton: View {
    let icon: String
    let action: () -> Void
    var size: CGFloat = 48
    var showGlow: Bool = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.38, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: size, height: size)
                .background(TPDesign.accentGradient)
                .clipShape(Circle())
                .shadowLarge()
        }
        .buttonStyle(CinematicButtonStyle())
        .if(showGlow) { view in
            view.pulseGlow(color: .tpAccent, radius: 20)
        }
    }
}

// MARK: - Chip Button (Selectable)

struct CinematicChipButton: View {
    let title: String
    let icon: String?
    let isSelected: Bool
    let action: () -> Void

    init(title: String, icon: String? = nil, isSelected: Bool, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background {
                if isSelected {
                    TPDesign.accentGradient
                } else {
                    Color.tpSurface
                }
            }
            .foregroundStyle(isSelected ? .white : TPDesign.textSecondary)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : TPDesign.divider, lineWidth: 1)
            )
        }
        .buttonStyle(CinematicButtonStyle())
    }
}

// MARK: - View Modifier Helper

extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
