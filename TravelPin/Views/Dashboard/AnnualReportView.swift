import SwiftUI
import SwiftData

struct AnnualReportView: View {
    let year: Int
    let travels: [Travel]

    @Environment(\.modelContext) private var modelContext
    @State private var aiSummary: String = ""
    @State private var isGenerating: Bool = false

    // MARK: - Computed Stats

    private var totalTrips: Int {
        travels.count
    }

    private var totalSpots: Int {
        travels.reduce(0) { $0 + $1.spots.filter { $0.status == .travelled }.count }
    }

    private var totalDays: Int {
        travels.reduce(0) { $0 + $1.durationDays }
    }

    private var totalPhotos: Int {
        travels.reduce(0) { $0 + $1.spots.reduce(0) { $0 + $1.photos.count } }
    }

    private var topTravels: [Travel] {
        travels.sorted { $0.spots.filter { $0.status == .travelled }.count > $1.spots.filter { $0.status == .travelled }.count }
            .prefix(3)
            .map { $0 }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                heroHeader

                VStack(spacing: 28) {
                    statsGrid

                    typeDistributionSection

                    topTripsSection

                    aiSummarySection

                    if !aiSummary.isEmpty {
                        shareSection
                    }

                    // Extra clearance for the floating tab bar
                    Spacer(minLength: 120)
                }
                .padding(.horizontal)
                .padding(.top, 28)
            }
        }
        .background(TPDesign.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(String(format: "annual.title".localized, "\(year)"))
                    .font(TPDesign.overline())
                    .foregroundStyle(TPDesign.textSecondary)
            }
        }
    }

    // MARK: - 1. Hero Header

    private var heroHeader: some View {
        ZStack {
            TPDesign.cinematicGradient
                .ignoresSafeArea()

            VStack(spacing: 8) {
                Text("\(year)")
                    .font(TPDesign.editorialSerif(72))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 4)

                Text(locKey: "annual.subtitle")
                    .font(TPDesign.bodyFont(16))
                    .foregroundStyle(.white.opacity(0.7))
                    .trackingMedium()
            }
            .padding(.vertical, 48)
        }
        .frame(height: 220)
        .clipped()
        .cinematicFadeIn(delay: 0.05)
    }

    // MARK: - 2. Stats Grid (2x2)

    private var statsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 12) {
            StatCardCell(
                value: "\(totalTrips)",
                label: "annual.stat.trips".localized,
                icon: "airplane",
                iconColor: TPDesign.celestialBlue
            )

            StatCardCell(
                value: "\(totalSpots)",
                label: "annual.stat.spots".localized,
                icon: "mappin",
                iconColor: TPDesign.warmAmber
            )

            StatCardCell(
                value: "\(totalDays)",
                label: "annual.stat.days".localized,
                icon: "calendar",
                iconColor: TPDesign.warmGold
            )

            StatCardCell(
                value: "\(totalPhotos)",
                label: "annual.stat.photos".localized,
                icon: "camera",
                iconColor: TPDesign.marineDeep
            )
        }
        .cinematicFadeIn(delay: 0.1)
    }

    // MARK: - 3. Travel Type Pie

    private var typeDistributionSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(locKey: "footprint.section.distribution")
                .font(TPDesign.editorialSerif(24))
                .foregroundStyle(TPDesign.obsidian)

            let distributionData = TravelType.allCases.compactMap { type -> (type: TravelType, count: Int)? in
                let count = travels.filter { $0.type == type }.count
                return count > 0 ? (type, count) : nil
            }
            let totalCount = distributionData.reduce(0) { $0 + $1.count }

            HStack(spacing: 32) {
                // Circular Distribution Chart (Donut)
                ZStack {
                    Circle()
                        .stroke(TPDesign.alabaster.opacity(0.8), lineWidth: 18)

                    if totalCount > 0 {
                        let colors: [Color] = [TPDesign.celestialBlue, TPDesign.warmAmber, TPDesign.marineDeep, TPDesign.warmGold, TPDesign.leicaRed]

                        ForEach(0..<distributionData.count, id: \.self) { index in
                            let segment = distributionData[index]
                            let previousCount = distributionData.prefix(index).reduce(0) { $0 + $1.count }
                            let start = Double(previousCount) / Double(totalCount)
                            let end = Double(previousCount + segment.count) / Double(totalCount)

                            Circle()
                                .trim(from: start, to: end)
                                .stroke(colors[index % colors.count], style: StrokeStyle(lineWidth: 18, lineCap: .butt))
                                .rotationEffect(.degrees(-90))
                        }
                    } else {
                        Circle()
                            .stroke(style: StrokeStyle(lineWidth: 18, dash: [2, 4]))
                            .foregroundStyle(TPDesign.divider)
                    }

                    VStack(spacing: 2) {
                        Text("\(totalCount)")
                            .font(TPDesign.editorialSerif(28))
                            .foregroundStyle(TPDesign.obsidian)
                        Text(locKey: "nav.journeys")
                            .font(TPDesign.overline())
                            .foregroundStyle(TPDesign.textTertiary)
                    }
                }
                .frame(width: 140, height: 140)
                .padding(10)

                // Legend
                VStack(alignment: .leading, spacing: 14) {
                    let sortedData = distributionData.sorted { $0.count > $1.count }
                    let colors: [Color] = [TPDesign.celestialBlue, TPDesign.warmAmber, TPDesign.marineDeep, TPDesign.warmGold, TPDesign.leicaRed]

                    ForEach(0..<min(sortedData.count, 5), id: \.self) { index in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(colors[index % colors.count])
                                .frame(width: 8, height: 8)
                            Text(sortedData[index].type.displayName)
                                .font(TPDesign.bodyFont(14))
                                .foregroundStyle(TPDesign.textSecondary)
                            Spacer()
                            Text("\(sortedData[index].count)")
                                .font(TPDesign.bodyFont(14).bold())
                                .foregroundStyle(TPDesign.textPrimary)
                        }
                    }
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(TPDesign.secondaryBackground.opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(TPDesign.obsidian.opacity(0.1), lineWidth: 0.5)
                    )
            )
            .shadowSmall()
        }
        .cinematicFadeIn(delay: 0.15)
    }

    // MARK: - 4. Top Trips

    private var topTripsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(locKey: "annual.top_trips")
                .font(TPDesign.editorialSerif(24))
                .foregroundStyle(TPDesign.obsidian)

            if topTravels.isEmpty {
                emptyTopTripsPlaceholder
            } else {
                ForEach(Array(topTravels.enumerated()), id: \.element.id) { index, travel in
                    HStack(spacing: 14) {
                        // Rank badge
                        ZStack {
                            Circle()
                                .fill(rankColor(for: index).opacity(0.12))
                                .frame(width: 36, height: 36)
                            Text("#\(index + 1)")
                                .font(TPDesign.captionFont())
                                .foregroundStyle(rankColor(for: index))
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(travel.name)
                                .font(TPDesign.bodyFont(16, weight: .semibold))
                                .foregroundStyle(TPDesign.textPrimary)
                                .lineLimit(1)

                            HStack(spacing: 8) {
                                Text(travel.startDate.formatted(.dateTime.year().month()))
                                    .font(.caption)
                                    .foregroundStyle(TPDesign.textSecondary)

                                Text("\(travel.spots.filter { $0.status == .travelled }.count) " + "common.spots".localized)
                                    .font(.caption)
                                    .foregroundStyle(TPDesign.textTertiary)
                            }
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(TPDesign.textTertiary)
                    }
                    .padding()
                    .contentShape(Rectangle())
                    .glassCard(cornerRadius: 16)
                    .cinematicFadeIn(delay: Double(index) * 0.08 + 0.2)
                }
            }
        }
        .cinematicFadeIn(delay: 0.2)
    }

    private var emptyTopTripsPlaceholder: some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "map")
                    .font(.system(size: 28))
                    .foregroundStyle(TPDesign.textTertiary)
                Text(locKey: "dashboard.empty.subtitle")
                    .font(TPDesign.bodyFont(14))
                    .foregroundStyle(TPDesign.textTertiary)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 32)
            Spacer()
        }
        .glassCard(cornerRadius: 16)
    }

    // MARK: - 5. AI Summary Section

    private var aiSummarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(locKey: "annual.ai_summary")
                .font(TPDesign.editorialSerif(24))
                .foregroundStyle(TPDesign.obsidian)

            if aiSummary.isEmpty && !isGenerating {
                CinematicPrimaryButton(
                    locKey: "annual.generate",
                    icon: "sparkles",
                    isLoading: false
                ) {
                    generateAISummary()
                }
            }

            if isGenerating {
                HStack(spacing: 12) {
                    ProgressView()
                        .tint(TPDesign.celestialBlue)
                    Text(locKey: "annual.generating")
                        .font(TPDesign.bodyFont(14))
                        .foregroundStyle(TPDesign.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .glassCard(cornerRadius: 16)
            }

            if !aiSummary.isEmpty {
                ScrollView {
                    Text(aiSummary)
                        .font(TPDesign.bodyFont(15))
                        .foregroundStyle(TPDesign.textPrimary)
                        .lineSpacing(6)
                        .textSelection(.enabled)
                }
                .frame(maxHeight: 400)
                .padding()
                .glassCard(cornerRadius: 16)
                .cinematicFadeIn(delay: 0.1)
            }
        }
        .cinematicFadeIn(delay: 0.25)
    }

    // MARK: - 6. Share Section

    private var shareSection: some View {
        Group {
            if let shareText = prepareShareText() {
                ShareLink(
                    item: shareText,
                    subject: Text(String(format: "annual.title".localized, "\(year)")),
                    message: Text(shareText)
                ) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14, weight: .semibold))
                        Text(locKey: "annual.share")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(TPDesign.accentGradient)
                    .clipShape(Capsule())
                    .shadowLarge()
                }
                .buttonStyle(CinematicButtonStyle())
            }
        }
        .cinematicFadeIn(delay: 0.3)
    }

    // MARK: - Helpers

    private func rankColor(for index: Int) -> Color {
        switch index {
        case 0: return TPDesign.warmGold
        case 1: return TPDesign.textSecondary
        case 2: return TPDesign.warmAmber
        default: return TPDesign.celestialBlue
        }
    }

    private func generateAISummary() {
        guard !isGenerating else { return }
        isGenerating = true

        Task {
            do {
                let result = try await AIAssistantService.shared.generateAnnualReport(for: year, travels: travels)
                await MainActor.run {
                    aiSummary = result
                    isGenerating = false
                }
            } catch {
                await MainActor.run {
                    aiSummary = "common.error.network".localized
                    isGenerating = false
                }
            }
        }
    }

    private func prepareShareText() -> String? {
        guard !aiSummary.isEmpty else { return nil }
        let header = String(format: "annual.title".localized, "\(year)")
        return "\(header)\n\n\(aiSummary)"
    }
}

// MARK: - Stat Card Cell

private struct StatCardCell: View {
    let value: String
    let label: String
    let icon: String
    let iconColor: Color

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(iconColor)
            }
            .overlay(
                Circle()
                    .stroke(iconColor.opacity(0.2), lineWidth: 0.5)
            )

            Text(value)
                .font(TPDesign.editorialSerif(28))
                .foregroundStyle(TPDesign.textPrimary)

            Text(label)
                .font(TPDesign.overline())
                .foregroundStyle(TPDesign.textSecondary)
                .trackingWide()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .glassCard(cornerRadius: TPDesign.radiusMedium)
        .shadowSmall()
    }
}

#Preview {
    NavigationStack {
        AnnualReportView(year: 2025, travels: [])
    }
}
