import SwiftUI

struct WeatherOverlayView: View {
    let weather: WeatherInfo
    @State private var isExpanded = false

    // MARK: - Weather Icon Resolution

    private var currentIcon: String {
        if weather.isRainy { return "cloud.rain.fill" }
        if weather.temperature > 30 { return "sun.max.fill" }
        if weather.temperature < 10 { return "snowflake" }
        return "cloud.sun.fill"
    }

    private func icon(for condition: String, temperature: Double, isRainy: Bool) -> String {
        if isRainy { return "cloud.rain.fill" }
        if temperature > 30 { return "sun.max.fill" }
        if temperature < 10 { return "snowflake" }
        return "cloud.sun.fill"
    }

    private var tempString: String {
        String(format: "weather.overlay.temp".localized, weather.temperature)
    }

    // MARK: - Body

    var body: some View {
        if isExpanded {
            expandedCard
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.8).combined(with: .opacity),
                    removal: .scale(scale: 0.9).combined(with: .opacity)
                ))
        } else {
            compactCapsule
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.9).combined(with: .opacity),
                    removal: .scale(scale: 0.8).combined(with: .opacity)
                ))
        }
    }

    // MARK: - Compact Capsule

    private var compactCapsule: some View {
        Button {
            TPHaptic.selection()
            withAnimation(TPDesign.springBouncy) {
                isExpanded = true
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: currentIcon)
                    .font(.system(size: 14, weight: .semibold))
                Text(tempString)
                    .font(TPDesign.captionFont())
            }
            .foregroundStyle(TPDesign.obsidian)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                Capsule()
                    .stroke(TPDesign.obsidian.opacity(0.1), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Expanded Card

    private var expandedCard: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("weather.overlay.expanded".localized)
                    .font(TPDesign.overline())
                    .tracking(1)
                    .foregroundStyle(TPDesign.textSecondary)

                Spacer()

                Button {
                    TPHaptic.selection()
                    withAnimation(TPDesign.springBouncy) {
                        isExpanded = false
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(TPDesign.textTertiary)
                }
            }
            .padding(.bottom, 16)

            // Current Temperature
            HStack(spacing: 16) {
                Image(systemName: currentIcon)
                    .font(.system(size: 40, weight: .medium))
                    .foregroundStyle(TPDesign.celestialBlue)
                    .symbolRenderingMode(.hierarchical)

                VStack(alignment: .leading, spacing: 2) {
                    Text(tempString)
                        .font(TPDesign.editorialSerif(36))
                        .foregroundStyle(TPDesign.obsidian)

                    Text(weather.condition)
                        .font(TPDesign.bodyFont(14, weight: .regular))
                        .foregroundStyle(TPDesign.textSecondary)
                }

                Spacer()
            }
            .padding(.bottom, 20)

            // Hourly Forecast
            VStack(alignment: .leading, spacing: 10) {
                Text("weather.overlay.hourly".localized)
                    .font(TPDesign.overline())
                    .tracking(1)
                    .foregroundStyle(TPDesign.textSecondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(Array(weather.hourlyForecast.prefix(6).enumerated()), id: \.offset) { index, hour in
                            hourCell(hour, isFirst: index == 0)
                        }
                    }
                }
            }
            .padding(.bottom, 20)

            // Rain Probability Bar
            if weather.isRainy {
                rainProbabilitySection
            }
        }
        .padding(20)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: TPDesign.radiusLarge)
                    .fill(.ultraThinMaterial.opacity(0.6))
                RoundedRectangle(cornerRadius: TPDesign.radiusLarge)
                    .fill(
                        LinearGradient(
                            colors: [TPDesign.celestialBlue.opacity(0.05), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: TPDesign.radiusLarge))
        .overlay(
            RoundedRectangle(cornerRadius: TPDesign.radiusLarge)
                .stroke(
                    LinearGradient(
                        colors: [TPDesign.obsidian.opacity(0.15), TPDesign.obsidian.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
        )
        .shadowMedium()
    }

    // MARK: - Hour Cell

    private func hourCell(_ hour: HourForecast, isFirst: Bool) -> some View {
        VStack(spacing: 6) {
            Text(isFirst ? "weather.overlay.now".localized : hourTimeString(hour.time))
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(TPDesign.textSecondary)

            Image(systemName: icon(
                for: hour.condition,
                temperature: hour.temperature,
                isRainy: hour.precipitationChance > 0.5
            ))
            .font(.system(size: 18))
            .foregroundStyle(TPDesign.obsidian)

            Text(String(format: "%.0f°", hour.temperature))
                .font(TPDesign.captionFont())
                .foregroundStyle(TPDesign.obsidian)
        }
        .frame(width: 52)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: TPDesign.radiusSmall)
                .fill(TPDesign.obsidian.opacity(0.04))
        )
    }

    // MARK: - Rain Probability

    private var rainProbabilitySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(format: "weather.overlay.rain_chance".localized, maxPrecipitationChance * 100))
                .font(TPDesign.captionFont())
                .foregroundStyle(TPDesign.textSecondary)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(TPDesign.obsidian.opacity(0.06))
                        .frame(height: 6)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [TPDesign.celestialBlue, TPDesign.marineDeep],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geometry.size.width * CGFloat(maxPrecipitationChance),
                            height: 6
                        )
                }
            }
            .frame(height: 6)
        }
    }

    private var maxPrecipitationChance: Double {
        let maxFromForecast = weather.hourlyForecast.prefix(6)
            .map(\.precipitationChance)
            .max() ?? 0
        return max(maxFromForecast, weather.isRainy ? 0.6 : 0)
    }

    // MARK: - Date Formatting

    private func hourTimeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
