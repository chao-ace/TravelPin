import SwiftUI
import PhotosUI
import SwiftData

// MARK: - Spot Check-In View

/// A compact card/sheet for confirming arrival at a spot.
/// Sets `spot.status = .travelled`, records `actualDate`, auto-captures weather,
/// and optionally attaches a quick photo before calling `onCheckIn()`.
struct SpotCheckInView: View {

    // MARK: - Parameters

    let spot: Spot
    let travel: Travel
    let onCheckIn: () -> Void
    let onSkip: () -> Void

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext

    // MARK: - State

    @State private var appeared = false
    @State private var checkmarkScale: CGFloat = 0.01
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var quickNotes: String = ""
    @State private var isCheckingIn = false
    @State private var showConfetti = false

    // Auto-captured weather data
    @State private var autoTemperature: Double?
    @State private var autoWeatherCondition: String?

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {

            // MARK: Arrival Header
            arrivalHeader
                .padding(.top, 32)
                .padding(.bottom, 16)

            // MARK: Spot Info
            spotInfoSection
                .padding(.horizontal, 24)
                .padding(.bottom, 20)

            // MARK: Weather Badge (auto-captured)
            if autoTemperature != nil || autoWeatherCondition != nil {
                weatherBadge
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
            }

            // MARK: Quick Notes
            quickNotesSection
                .padding(.horizontal, 24)
                .padding(.bottom, 24)

            // MARK: Action Buttons
            actionButtons
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
        }
        .glassCard(cornerRadius: TPDesign.radiusLarge)
        .padding(.horizontal, 20)
        .cinematicFadeIn()
        .overlay {
            if showConfetti {
                ConfettiView()
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            animateArrival()
            TPHaptic.notification(.success)
            captureWeatherData()
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem else { return }
            loadPhoto(from: newItem)
        }
    }

    // MARK: - Arrival Header

    private var arrivalHeader: some View {
        VStack(spacing: 12) {
            // Animated checkmark circle
            ZStack {
                Circle()
                    .fill(TPDesign.accentGradient)
                    .frame(width: 72, height: 72)
                    .scaleEffect(checkmarkScale)

                Image(systemName: "checkmark")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .scaleEffect(checkmarkScale)
            }

            Text("checkin.title".localized)
                .font(TPDesign.titleFont(22, weight: .bold))
                .foregroundStyle(TPDesign.textPrimary)

            Text(String(format: "checkin.subtitle".localized, spot.name))
                .font(TPDesign.bodyFont(14))
                .foregroundStyle(TPDesign.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }

    // MARK: - Spot Info

    private var spotInfoSection: some View {
        VStack(spacing: 10) {
            // Spot name in editorial serif
            Text(spot.name)
                .font(TPDesign.editorialSerif(28))
                .foregroundStyle(TPDesign.textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .multilineTextAlignment(.center)

            // Spot type badge
            HStack(spacing: 6) {
                Image(systemName: spot.type.icon)
                    .font(.system(size: 11, weight: .semibold))
                Text(spot.type.displayName)
                    .font(TPDesign.overline())
                    .tracking(0.5)
            }
            .foregroundStyle(TPDesign.celestialBlue)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(TPDesign.celestialBlue.opacity(0.1))
            .clipShape(Capsule())

            // Suggested visit duration hint
            if let duration = spot.visitDuration {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 10))
                    Text(String(format: "checkin.duration.hint".localized, duration))
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(TPDesign.textTertiary)
                .padding(.top, 4)
            }
        }
    }

    // MARK: - Weather Badge

    private var weatherBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: temperatureIcon(autoTemperature ?? 20))
                .font(.system(size: 14))
                .foregroundStyle(TPDesign.celestialBlue)

            if let temp = autoTemperature {
                Text(String(format: "%.0f°C", temp))
                    .font(TPDesign.bodyFont(14, weight: .medium))
            }

            if let condition = autoWeatherCondition {
                Text("·")
                    .foregroundStyle(.tertiary)
                Text(condition)
                    .font(TPDesign.captionFont())
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("checkin.weather.auto".localized)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.tertiary)
                .textCase(.uppercase)
        }
        .padding(12)
        .background(TPDesign.celestialBlue.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Quick Notes

    private var quickNotesSection: some View {
        TextField("checkin.notes.placeholder".localized, text: $quickNotes, axis: .vertical)
            .font(TPDesign.bodyFont(14))
            .lineLimit(2...4)
            .padding(12)
            .background(TPDesign.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: TPDesign.radiusSmall))
            .overlay(
                RoundedRectangle(cornerRadius: TPDesign.radiusSmall)
                    .stroke(TPDesign.divider, lineWidth: 0.5)
            )
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Top row: Quick Photo + Check In
            HStack(spacing: 12) {
                // Quick Photo
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    HStack(spacing: 6) {
                        Image(systemName: "camera")
                            .font(.system(size: 14, weight: .semibold))
                        Text("checkin.photo".localized)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(Color.tpAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.tpAccent.opacity(0.08))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color.tpAccent.opacity(0.3), lineWidth: 1.5)
                    )
                }
                .buttonStyle(CinematicButtonStyle())

                // Check In (Primary)
                CinematicPrimaryButton(
                    locKey: "checkin.action",
                    icon: "checkmark.circle",
                    isLoading: isCheckingIn
                ) {
                    performCheckIn()
                }
            }

            // Skip
            Button {
                TPHaptic.selection()
                onSkip()
            } label: {
                Text("checkin.skip".localized)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(TPDesign.textTertiary)
            }
            .buttonStyle(CinematicButtonStyle())
        }
    }

    // MARK: - Animations

    private func animateArrival() {
        withAnimation(TPDesign.luxurySpring.delay(0.1)) {
            checkmarkScale = 1.0
        }
    }

    // MARK: - Weather Auto-Capture

    private func captureWeatherData() {
        Task {
            // Try IntelligenceService's cached weather first
            if let weather = IntelligenceService.shared.currentWeather {
                autoTemperature = weather.temperature
                autoWeatherCondition = weather.condition
                return
            }

            // Fallback: fetch directly for this spot's location
            if let coord = spot.coordinate {
                if let weather = await IntelligenceService.shared.fetchWeatherForSpot(coord: coord) {
                    autoTemperature = weather.temperature
                    autoWeatherCondition = weather.condition
                }
            }
        }
    }

    // MARK: - Actions

    private func performCheckIn() {
        isCheckingIn = true
        TPHaptic.mechanicalPress()

        // Update spot status
        spot.status = .travelled
        spot.actualDate = Date()

        // Auto-capture weather data into the spot model
        spot.arrivalTemperature = autoTemperature
        spot.arrivalWeatherCondition = autoWeatherCondition

        // Attach quick notes if provided
        if !quickNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            if spot.notes.isEmpty {
                spot.notes = quickNotes
            } else {
                spot.notes += "\n" + quickNotes
            }
        }

        // Persist
        try? modelContext.save()

        // Show confetti, then dismiss
        showConfetti = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            showConfetti = false
            isCheckingIn = false
            onCheckIn()
        }
    }

    private func loadPhoto(from item: PhotosPickerItem) {
        Task {
            guard let data = try? await item.loadTransferable(type: Data.self) else { return }
            let photo = TravelPhoto(data: data)
            spot.photos.append(photo)
            try? modelContext.save()
            TPHaptic.selection()
        }
    }

    // MARK: - Helpers

    private func temperatureIcon(_ temp: Double) -> String {
        if temp < 5 { return "snowflake" }
        else if temp < 15 { return "cloud" }
        else if temp < 28 { return "sun.max" }
        else { return "thermometer.sun" }
    }
}
