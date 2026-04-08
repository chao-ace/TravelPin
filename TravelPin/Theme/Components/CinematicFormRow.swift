import SwiftUI

// MARK: - Cinematic Form Section (replaces Section)

struct CinematicFormSection<Content: View>: View {
    let titleLocKey: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Overline header
            Text(locKey: titleLocKey)
                .font(TPDesign.overline())
                .foregroundStyle(TPDesign.textTertiary)
                .tracking(2)
                .textCase(.uppercase)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                content()
            }
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: TPDesign.radiusLarge))
            .overlay(
                RoundedRectangle(cornerRadius: TPDesign.radiusLarge)
                    .stroke(TPDesign.obsidian.opacity(0.1), lineWidth: 1)
            )

            .shadowSmall()
        }
    }
}

// MARK: - Cinematic Form Row (replaces default Form row)

struct CinematicFormRow<Content: View>: View {
    let icon: String
    var iconColor: Color = .tpAccent
    @ViewBuilder let content: () -> Content

    var body: some View {
        HStack(spacing: 14) {
            // Icon circle
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(width: 36, height: 36)
                .background(iconColor.opacity(0.1))
                .clipShape(Circle())

            // Content area
            content()

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Cinematic Form Divider

struct CinematicFormDivider: View {
    var body: some View {
        Rectangle()
            .fill(TPDesign.divider.opacity(0.5))
            .frame(height: 0.5)
            .padding(.leading, 66)
    }
}

// MARK: - Cinematic Form Title Row (icon + label + value)

struct CinematicFormLabelRow: View {
    let icon: String
    var iconColor: Color = .tpAccent
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(width: 36, height: 36)
                .background(iconColor.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(TPDesign.captionFont())
                    .foregroundStyle(TPDesign.textTertiary)
                Text(value)
                    .font(TPDesign.bodyFont())
                    .foregroundStyle(TPDesign.textPrimary)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
