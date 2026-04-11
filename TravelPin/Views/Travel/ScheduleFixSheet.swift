import SwiftUI
import SwiftData

/// Displays a scheduling conflict with actionable fix options.
struct ScheduleFixSheet: View {
    let fix: ScheduleFix
    let travel: Travel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var appliedActionId: UUID?

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                // Alert description
                VStack(alignment: .leading, spacing: 8) {
                    Image(systemName: fixIcon)
                        .font(.system(size: 32))
                        .foregroundStyle(TPDesign.warmAmber)

                    Text(fix.alertTitle)
                        .font(TPDesign.editorialSerif(22))
                        .foregroundStyle(TPDesign.obsidian)

                    Text(fix.alertMessage)
                        .font(TPDesign.bodyFont())
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 24)

                // Fix actions
                VStack(spacing: 12) {
                    ForEach(fix.actions) { action in
                        Button {
                            applyFix(action)
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(Color.tpAccent.opacity(0.1))
                                        .frame(width: 40, height: 40)
                                    Image(systemName: action.icon)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(Color.tpAccent)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(action.title)
                                        .font(TPDesign.bodyFont(15, weight: .bold))
                                        .foregroundStyle(TPDesign.obsidian)
                                    Text(action.subtitle)
                                        .font(TPDesign.captionFont())
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                if appliedActionId == action.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundStyle(.green)
                                } else {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            .padding(16)
                            .background(TPDesign.secondaryBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .buttonStyle(.plain)
                        .disabled(appliedActionId != nil)
                    }
                }
                .padding(.horizontal, 24)

                Spacer()
            }
            .padding(.top, 24)
            .background(TPDesign.background)
            .navigationTitle(locKey: "logic.fix.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.done".localized) { dismiss() }
                }
            }
        }
    }

    private var fixIcon: String {
        switch fix.fixType {
        case .timeOverlap:    return "clock.badge.exclamationmark"
        case .distanceTooFar: return "map.badge.exclamationmark"
        case .weatherChange:  return "cloud.bolt.rain"
        }
    }

    private func applyFix(_ action: FixAction) {
        switch action.actionType {
        case .shiftLater(let spotId, let minutes):
            if let spot = travel.spots.first(where: { $0.id == spotId }),
               let estimated = spot.estimatedDate {
                spot.estimatedDate = estimated.addingTimeInterval(TimeInterval(minutes * 60))
            }

        case .skipSpot(let spotId):
            if let spot = travel.spots.first(where: { $0.id == spotId }) {
                spot.status = .cancelled
            }

        case .swapWithAlternative(let originalSpotId):
            // Mark the spot as needing re-planning (user will manually replace)
            if let spot = travel.spots.first(where: { $0.id == originalSpotId }) {
                spot.status = .cancelled
            }

        case .suggestIndoor(let spotId):
            // Flag the spot for indoor alternative suggestion
            if let spot = travel.spots.first(where: { $0.id == spotId }) {
                spot.notes = (spot.notes.isEmpty ? "" : spot.notes + "\n") + "logic.fix.indoor_note".localized
            }
        }

        try? modelContext.save()
        withAnimation {
            appliedActionId = action.id
        }
        TPHaptic.notification(.success)

        // Auto-dismiss after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            dismiss()
        }
    }
}
