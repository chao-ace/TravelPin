import SwiftUI

/// Step 1: Name and travel type selection with visual icon grid and smart recommendations.
struct WizardStepNameType: View {
    @Binding var name: String
    @Binding var selectedType: TravelType
    let recommendedType: TravelType?

    /// Tracks whether the user has touched the name field (for real-time validation)
    @State private var nameTouched = false

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 28) {
                // Section header
                VStack(alignment: .leading, spacing: 8) {
                    Text(locKey: "wizard.step1.title")
                        .font(TPDesign.editorialSerif(28))
                        .foregroundStyle(TPDesign.obsidian)
                    Text(locKey: "wizard.step1.subtitle")
                        .font(TPDesign.bodyFont(14))
                        .foregroundStyle(.secondary)
                }

                // Name input with real-time validation
                CinematicFormSection(titleLocKey: "wizard.step1.name_section") {
                    VStack(alignment: .leading, spacing: 0) {
        CinematicTextField(
                            placeholderLocKey: "add.travel.name",
                            text: $name,
                            icon: "pencil.and.outline"
                        )
                        .onChange(of: name) { _ in
                            if !nameTouched { nameTouched = true }
                        }

                        // Real-time validation hint
                        if nameTouched && name.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.circle")
                                    .font(.system(size: 11))
                                Text(locKey: "wizard.step1.name_required")
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .foregroundStyle(TPDesign.leicaRed)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .transition(.opacity)
                        } else if !name.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 11))
                                Text(locKey: "wizard.step1.name_ok")
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .foregroundStyle(.green)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .transition(.opacity)
                        }
                    }
                }

                // Type selection — visual icon grid
                CinematicFormSection(titleLocKey: "wizard.step1.type_section") {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(TravelType.allCases, id: \.self) { type in
                            typeGridItem(type)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
    }

    // MARK: - Type Grid Item

    private func typeGridItem(_ type: TravelType) -> some View {
        let isSelected = selectedType == type
        let isRecommended = recommendedType == type

        return Button {
            TPHaptic.selection()
            withAnimation(TPDesign.springDefault) {
                selectedType = type
            }
        } label: {
            VStack(spacing: 10) {
                ZStack {
                    // Background circle
                    Circle()
                        .fill(isSelected ? Color.tpAccent.opacity(0.12) : TPDesign.alabaster)
                        .frame(width: 56, height: 56)

                    Image(systemName: type.icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(isSelected ? Color.tpAccent : .secondary)
                        .symbolEffect(.bounce, value: isSelected)
                }

                VStack(spacing: 2) {
                    Text(type.displayName)
                        .font(TPDesign.bodyFont(13, weight: isSelected ? .bold : .medium))
                        .foregroundStyle(isSelected ? TPDesign.obsidian : .secondary)
                        .lineLimit(1)

                    if isRecommended {
                        Text(locKey: "wizard.type.recommended")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Color.tpAccent)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.tpAccent.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.tpAccent.opacity(0.06) : TPDesign.secondaryBackground.opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.tpAccent.opacity(0.4) : TPDesign.alabaster.opacity(0.5), lineWidth: isSelected ? 1.5 : 0.5)
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(TPDesign.springDefault, value: selectedType)
        }
        .buttonStyle(.plain)
    }
}
