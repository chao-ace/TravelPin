import SwiftUI

/// A rich real-time card displayed during active travel.
/// Shows current/next spot, distance, suggested departure, weather, fatigue, and progress.
struct NowPlayingCard: View {
    let state: NowState
    let travel: Travel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // MARK: - Top Row: Current Spot + Progress Ring
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(locKey: "now.playing.title")
                        .font(TPDesign.overline())
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    if let current = state.currentSpot {
                        HStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(Color.tpAccent.opacity(0.12))
                                    .frame(width: 36, height: 36)
                                Image(systemName: current.type.icon)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(Color.tpAccent)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(current.name)
                                    .font(TPDesign.bodyFont(16, weight: .bold))
                                    .lineLimit(1)
                                if let time = current.estimatedDate {
                                    Text(time.formatted(.dateTime.hour().minute()))
                                        .font(TPDesign.captionFont())
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    } else {
                        Text(locKey: "now.playing.free_time")
                            .font(TPDesign.bodyFont(16, weight: .bold))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                ProgressRingView(
                    progress: state.progressRatio,
                    lineWidth: 5,
                    size: 52,
                    showLabel: true,
                    labelStyle: .fraction(filled: state.progressVisited, total: state.progressTotal)
                )
            }

            // MARK: - Next Spot Row
            if let next = state.nextSpot {
                HStack(spacing: 12) {
                    // Connector line
                    Rectangle()
                        .fill(Color.tpAccent.opacity(0.3))
                        .frame(width: 2, height: 24)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(locKey: "now.playing.next")
                            .font(TPDesign.overline())
                            .foregroundStyle(.secondary)

                        HStack(spacing: 6) {
                            Image(systemName: next.type.icon)
                                .font(.system(size: 11))
                                .foregroundStyle(Color.tpAccent)
                            Text(next.name)
                                .font(TPDesign.bodyFont(14, weight: .semibold))
                                .lineLimit(1)
                        }

                        HStack(spacing: 12) {
                            if let distance = state.distanceText {
                                Label(distance, systemImage: "point.topleft.down.to.point.bottomright.curvepath")
                                    .font(TPDesign.captionFont())
                                    .foregroundStyle(.secondary)
                            }
                            if let departure = state.departureTimeText {
                                Label(departure, systemImage: "clock")
                                    .font(TPDesign.captionFont())
                                    .foregroundStyle(Color.tpAccent)
                            }
                        }
                    }
                }
                .padding(.leading, 4)
            }

            // MARK: - Bottom Bar: Weather + Clothing | Fatigue
            HStack(spacing: 0) {
                // Weather
                if let temp = state.temperature {
                    HStack(spacing: 6) {
                        Image(systemName: temperatureIcon(temp))
                            .font(.system(size: 13))
                        Text(String(format: "%.0f°C", temp))
                            .font(TPDesign.bodyFont(13, weight: .medium))
                    }
                    .foregroundStyle(.secondary)

                    if let hint = state.clothingHint {
                        Text("·")
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, 2)
                        Text(hint)
                            .font(TPDesign.captionFont())
                            .foregroundStyle(TPDesign.warmAmber)
                    }
                } else {
                    Text(locKey: "now.playing.no_weather")
                        .font(TPDesign.captionFont())
                        .foregroundStyle(.tertiary)
                }

                Spacer()

                // Fatigue indicator
                fatigueView
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(TPDesign.secondaryBackground)
                .shadowMedium()
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.tpAccent.opacity(0.12), lineWidth: 1)
        )
        .padding(.horizontal)
    }

    // MARK: - Helpers

    @ViewBuilder
    private var fatigueView: some View {
        HStack(spacing: 5) {
            // Three-segment bar
            HStack(spacing: 2) {
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(fatigueColor.opacity(state.fatigueLevel == .high ? 1 : 0.25))
                    .frame(width: 6, height: 12)
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(fatigueColor.opacity(state.fatigueLevel != .low ? 1 : 0.25))
                    .frame(width: 6, height: 12)
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(fatigueColor.opacity(1))
                    .frame(width: 6, height: 12)
            }

            Text(state.fatigueLevel.label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(fatigueColor)
        }
    }

    private var fatigueColor: Color {
        switch state.fatigueLevel {
        case .low:      return .green
        case .moderate: return .orange
        case .high:     return TPDesign.leicaRed
        }
    }

    private func temperatureIcon(_ temp: Double) -> String {
        if temp < 5 { return "snowflake" }
        else if temp < 15 { return "cloud" }
        else if temp < 28 { return "sun.max" }
        else { return "thermometer.sun" }
    }
}
