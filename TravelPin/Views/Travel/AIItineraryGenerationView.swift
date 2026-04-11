import SwiftUI
import SwiftData

struct AIItineraryGenerationView: View {
    let travel: Travel

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var drafts: [ItineraryDraft] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var adoptedDraftIds: Set<UUID> = []
    @State private var showingUpgrade = false

    var body: some View {
        NavigationStack {
            ZStack {
                TPDesign.background.ignoresSafeArea()

                if isLoading {
                    loadingView
                } else if let errorMessage {
                    errorView(message: errorMessage)
                } else if drafts.isEmpty {
                    initialView
                } else {
                    resultsView
                }
            }
            .navigationTitle("ai.itinerary.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("common.close".localized) { dismiss() }
                }
            }
            .sheet(isPresented: $showingUpgrade) {
                NavigationStack {
                    TravelPinAIView()
                }
            }
        }
    }

    // MARK: - Initial View (before generation)

    private var initialView: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "map")
                .font(.system(size: 72))
                .foregroundStyle(Color.tpAccent)
                .cinematicFadeIn()

            VStack(spacing: 12) {
                Text(travel.name)
                    .font(TPDesign.titleFont(24))
                    .foregroundStyle(TPDesign.textPrimary)
                    .multilineTextAlignment(.center)

                HStack(spacing: 16) {
                    Label("\(travel.durationDays) " + "common.days".localized, systemImage: "calendar")
                    Label(travel.type.displayName, systemImage: travel.type.icon)
                }
                .font(TPDesign.bodyFont(14, weight: .medium))
                .foregroundStyle(TPDesign.textSecondary)
            }
            .cinematicFadeIn(delay: 0.1)

            CinematicPrimaryButton(
                locKey: "ai.itinerary.generate",
                icon: "sparkles",
                isLoading: isLoading
            ) {
                generateItinerary()
            }
            .padding(.horizontal, 32)
            .cinematicFadeIn(delay: 0.2)

            Spacer()
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 24) {
            Spacer()

            ProgressView()
                .scaleEffect(1.5)
                .tint(Color.tpAccent)

            Text("ai.itinerary.loading".localized)
                .font(TPDesign.bodyFont())
                .foregroundStyle(TPDesign.textSecondary)

            Spacer()
        }
    }

    // MARK: - Error View

    private func errorView(message: String) -> some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(TPDesign.warmAmber)

            Text(message)
                .font(TPDesign.bodyFont())
                .foregroundStyle(TPDesign.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            CinematicPrimaryButton(
                locKey: "ai.itinerary.generate",
                icon: "arrow.clockwise"
            ) {
                generateItinerary()
            }
            .padding(.horizontal, 32)

            Spacer()
        }
    }

    // MARK: - Results View

    private var resultsView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Travel info header
                travelInfoHeader
                    .cinematicFadeIn()

                // Day plan cards
                ForEach(Array(drafts.enumerated()), id: \.element.id) { index, draft in
                    ItineraryDraftCard(
                        draft: draft,
                        isAdopted: adoptedDraftIds.contains(draft.id)
                    ) {
                        adoptDraft(draft)
                    }
                    .cinematicFadeIn(delay: Double(index) * 0.08)
                }

                // Adopt All button
                if !drafts.isEmpty && adoptedDraftIds.count < drafts.count {
                    CinematicPrimaryButton(
                        locKey: "ai.itinerary.adopt_all",
                        icon: "checkmark.circle"
                    ) {
                        adoptAllDrafts()
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                    .cinematicFadeIn(delay: Double(drafts.count) * 0.08 + 0.1)
                } else if adoptedDraftIds.count == drafts.count {
                    allAdoptedView
                        .padding(.bottom, 32)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
    }

    // MARK: - Travel Info Header

    private var travelInfoHeader: some View {
        HStack(spacing: 12) {
            Image(systemName: travel.type.icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(TPDesign.accentGradient)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(travel.name)
                    .font(TPDesign.bodyFont(15, weight: .semibold))
                    .foregroundStyle(TPDesign.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text("\(travel.durationDays) " + "common.days".localized)
                    Text("\u{00B7}")
                    Text(travel.type.displayName)
                }
                .font(TPDesign.captionFont())
                .foregroundStyle(TPDesign.textSecondary)
            }

            Spacer()

            Text("\(drafts.count) " + "common.days".localized)
                .font(TPDesign.overline())
                .foregroundStyle(Color.tpAccent)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.tpAccent.opacity(0.08))
                .clipShape(Capsule())
        }
        .padding(16)
        .background(TPDesign.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: TPDesign.radiusMedium))
        .overlay(
            RoundedRectangle(cornerRadius: TPDesign.radiusMedium)
                .stroke(TPDesign.divider.opacity(0.5), lineWidth: 0.5)
        )
        .shadowSmall()
    }

    // MARK: - All Adopted View

    private var allAdoptedView: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 28))
                .foregroundStyle(Color.tpAccent)

            Text("common.done".localized)
                .font(TPDesign.bodyFont(15, weight: .semibold))
                .foregroundStyle(TPDesign.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    // MARK: - Actions

    private func generateItinerary() {
        isLoading = true
        errorMessage = nil
        drafts = []
        adoptedDraftIds = []

        Task {
            do {
                let result = try await AIAssistantService.shared.generateItinerary(for: travel)
                await MainActor.run {
                    drafts = result.sorted { $0.day < $1.day }
                    isLoading = false
                    if !result.isEmpty {
                        TPHaptic.notification(.success)
                    }
                }
            } catch AIProviderError.usageLimitExceeded {
                await MainActor.run {
                    isLoading = false
                    showingUpgrade = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = "ai.itinerary.error".localized
                    isLoading = false
                    TPHaptic.notification(.error)
                }
            }
        }
    }

    private func adoptDraft(_ draft: ItineraryDraft) {
        TPHaptic.mechanicalPress()

        // Create Itinerary
        let itinerary = Itinerary(
            day: draft.day,
            origin: draft.origin,
            destination: draft.destination
        )
        itinerary.travel = travel

        // Create Spots and link to itinerary
        for (index, spotName) in draft.suggestedSpots.enumerated() {
            let spot = Spot(
                name: spotName,
                type: SpotType.sightseeing.rawValue,
                status: SpotStatus.planning.rawValue,
                sequence: index + 1,
                notes: ""
            )
            spot.travel = travel
            spot.itinerary = itinerary
            modelContext.insert(spot)
        }

        modelContext.insert(itinerary)
        adoptedDraftIds.insert(draft.id)

        ToastManager.shared.show(type: .success, message: "ai.itinerary.adopt".localized)
    }

    private func adoptAllDrafts() {
        TPHaptic.mechanicalPress()

        for draft in drafts where !adoptedDraftIds.contains(draft.id) {
            let itinerary = Itinerary(
                day: draft.day,
                origin: draft.origin,
                destination: draft.destination
            )
            itinerary.travel = travel

            for (index, spotName) in draft.suggestedSpots.enumerated() {
                let spot = Spot(
                    name: spotName,
                    type: SpotType.sightseeing.rawValue,
                    status: SpotStatus.planning.rawValue,
                    sequence: index + 1,
                    notes: ""
                )
                spot.travel = travel
                spot.itinerary = itinerary
                modelContext.insert(spot)
            }

            modelContext.insert(itinerary)
            adoptedDraftIds.insert(draft.id)
        }

        TPHaptic.notification(.success)
    }
}

// MARK: - Itinerary Draft Card

private struct ItineraryDraftCard: View {
    let draft: ItineraryDraft
    let isAdopted: Bool
    let onAdopt: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Day header with route
            HStack(spacing: 12) {
                // Day badge
                Text("D\(draft.day)")
                    .font(TPDesign.overline())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(TPDesign.accentGradient)
                    .clipShape(Capsule())

                // Route
                VStack(alignment: .leading, spacing: 2) {
                    Text(routeText)
                        .font(TPDesign.bodyFont(15, weight: .semibold))
                        .foregroundStyle(TPDesign.textPrimary)

                    if let theme = draft.theme, !theme.isEmpty {
                        Text(theme)
                            .font(TPDesign.captionFont())
                            .foregroundStyle(TPDesign.textTertiary)
                    }
                }

                Spacer()

                // Adopt button
                Button(action: onAdopt) {
                    HStack(spacing: 4) {
                        Image(systemName: isAdopted ? "checkmark.circle.fill" : "plus.circle.fill")
                            .font(.system(size: 16))
                        Text(isAdopted ? "common.done".localized : "ai.itinerary.adopt".localized)
                            .font(TPDesign.captionFont())
                    }
                    .foregroundStyle(isAdopted ? Color.tpAccent : .white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background {
                        if isAdopted {
                            Capsule().fill(Color.tpAccent.opacity(0.1))
                        } else {
                            Capsule().fill(TPDesign.accentGradient)
                        }
                    }
                }
                .buttonStyle(CinematicButtonStyle())
                .disabled(isAdopted)
            }

            // Suggested spots as pills
            if !draft.suggestedSpots.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("ai.itinerary.spots".localized)
                        .font(TPDesign.overline())
                        .foregroundStyle(TPDesign.textTertiary)
                        .tracking(1)

                    FlowLayout(spacing: 8) {
                        ForEach(draft.suggestedSpots, id: \.self) { spotName in
                            SpotPill(name: spotName)
                        }
                    }
                }
            }
        }
        .padding(16)
        .glassCard(cornerRadius: TPDesign.radiusMedium)
        .opacity(isAdopted ? 0.65 : 1.0)
    }

    private var routeText: String {
        let o = draft.origin.trimmingCharacters(in: .whitespacesAndNewlines)
        let d = draft.destination.trimmingCharacters(in: .whitespacesAndNewlines)
        if o.isEmpty && d.isEmpty { return "" }
        if o.isEmpty { return d }
        if d.isEmpty { return o }
        return "\(o) \u{2192} \(d)"
    }
}

// MARK: - Spot Pill

private struct SpotPill: View {
    let name: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 10))
            Text(name)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .lineLimit(1)
        }
        .foregroundStyle(TPDesign.textSecondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(TPDesign.secondaryBackground)
        .clipShape(Capsule())
        .overlay(
            Capsule().stroke(TPDesign.divider.opacity(0.4), lineWidth: 0.5)
        )
    }
}

