import SwiftUI

/// Step 1: Name and travel type selection with smart recommendations.
struct WizardStepNameType: View {
    @Binding var name: String
    @Binding var selectedType: TravelType
    let recommendedType: TravelType?

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            // Section header
            VStack(alignment: .leading, spacing: 8) {
                Text(locKey: "wizard.step1.title")
                    .font(TPDesign.editorialSerif(28))
                    .foregroundStyle(TPDesign.obsidian)
                Text(locKey: "wizard.step1.subtitle")
                    .font(TPDesign.bodyFont(14))
                    .foregroundStyle(.secondary)
            }

            // Name input
            CinematicFormSection(titleLocKey: "wizard.step1.name_section") {
                CinematicTextField(
                    placeholderLocKey: "add.travel.name",
                    text: $name,
                    icon: "pencil.and.outline"
                )
            }

            // Type selection
            CinematicFormSection(titleLocKey: "wizard.step1.type_section") {
                VStack(spacing: 8) {
                    ForEach(TravelType.allCases, id: \.self) { type in
                        let isRecommended = recommendedType == type
                        Button {
                            withAnimation(TPDesign.springDefault) {
                                selectedType = type
                            }
                        } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(selectedType == type ? Color.tpAccent.opacity(0.15) : TPDesign.alabaster)
                                        .frame(width: 40, height: 40)
                                    Image(systemName: type.icon)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(selectedType == type ? Color.tpAccent : .secondary)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 6) {
                                        Text(type.displayName)
                                            .font(TPDesign.bodyFont(15, weight: selectedType == type ? .bold : .regular))
                                            .foregroundStyle(selectedType == type ? TPDesign.obsidian : .secondary)
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

                                Spacer()

                                if selectedType == type {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundStyle(Color.tpAccent)
                                }
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(selectedType == type ? Color.tpAccent.opacity(0.05) : .clear)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(selectedType == type ? Color.tpAccent.opacity(0.3) : .clear, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
}
