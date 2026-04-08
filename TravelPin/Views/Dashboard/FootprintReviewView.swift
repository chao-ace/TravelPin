import SwiftUI
import SwiftData

struct FootprintReviewView: View {
    @Query private var travels: [Travel]
    @Query private var spots: [Spot]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                headerSection

                statsGrid

                typeDistributionSection

                recentActivitySection
                
                // Extra clearance for the floating tab bar
                Spacer(minLength: 120)
            }
            .padding(.horizontal)
            .padding(.top)
        }
        .background(TPDesign.background.ignoresSafeArea())
        .navigationTitle("footprint.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .warmFilm(warmth: 0.05)
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(locKey: "footprint.header.title")
                .font(TPDesign.cinematicTitle(28))
                .foregroundStyle(
                    LinearGradient(
                        colors: [TPDesign.warmGold, TPDesign.warmAmber],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            Text(locKey: "footprint.header.subtitle")
                .font(TPDesign.bodyFont())
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(
            LinearGradient(
                colors: [TPDesign.warmAmber.opacity(0.08), TPDesign.warmGold.opacity(0.04), Color.clear],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: TPDesign.radiusLarge))
        .cinematicFadeIn(delay: 0.1)
    }

    private var statsGrid: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                NavigationLink(destination: StatDetailView(type: .journeys)) {
                    StatPill(
                        title: "footprint.stat.journeys_short".localized,
                        value: "\(travels.count)",
                        icon: "map.fill",
                        iconColor: TPDesign.celestialBlue
                    )
                }
                .buttonStyle(.plain)

                NavigationLink(destination: StatDetailView(type: .spots)) {
                    StatPill(
                        title: "footprint.stat.visited_short".localized,
                        value: "\(spots.count)",
                        icon: "mappin.and.ellipse",
                        iconColor: TPDesign.warmAmber
                    )
                }
                .buttonStyle(.plain)

                NavigationLink(destination: StatDetailView(type: .photos)) {
                    StatPill(
                        title: "footprint.stat.photos_short".localized,
                        value: "\(spots.reduce(0) { $0 + $1.photos.count })",
                        icon: "photo.stack",
                        iconColor: TPDesign.marineDeep
                    )
                }
                .buttonStyle(.plain)

                NavigationLink(destination: StatDetailView(type: .planning)) {
                    StatPill(
                        title: "footprint.stat.planning_short".localized,
                        value: "\(travels.filter { $0.status == .planning }.count)",
                        icon: "pencil.and.outline",
                        iconColor: TPDesign.warmGold
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 8)
        }
        .cinematicFadeIn(delay: 0.15)
    }

    struct StatPill: View {
        let title: String
        let value: String
        let icon: String
        let iconColor: Color

        var body: some View {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.1))
                        .frame(width: 32, height: 32)
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(iconColor)
                }
                .overlay(Circle().stroke(iconColor.opacity(0.2), lineWidth: 0.5))

                VStack(spacing: 2) {
                    Text(value)
                        .font(TPDesign.titleFont(18))
                        .foregroundStyle(TPDesign.textPrimary)
                    Text(title)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(TPDesign.textTertiary)
                        .trackingWide()
                }
            }
            .frame(width: 84)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(TPDesign.secondaryBackground.opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(TPDesign.obsidian.opacity(0.1), lineWidth: 0.5)
                    )

            )
            .shadowSmall()
        }
    }

    private var typeDistributionSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(locKey: "footprint.section.distribution")
                .font(TPDesign.editorialSerif(24))
                .foregroundStyle(TPDesign.obsidian)
                .padding(.horizontal, 8)

            let distributionData = TravelType.allCases.compactMap { type -> (type: TravelType, count: Int)? in
                let count = travels.filter { $0.type == type }.count
                return count > 0 ? (type, count) : nil
            }
            let totalCount = distributionData.reduce(0) { $0 + $1.count }

            HStack(spacing: 32) {
                // MARK: - Circular Distribution Chart (Ring/Donut)
                ZStack {
                    Circle()
                        .stroke(TPDesign.alabaster.opacity(0.8), lineWidth: 18)
                    
                    if totalCount > 0 {
                        let colors: [Color] = [TPDesign.celestialBlue, TPDesign.warmAmber, TPDesign.marineDeep, TPDesign.warmGold, TPDesign.leicaRed]
                        
                        // Using a simple loop to calculate offsets for the segments
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

                // MARK: - Smart Legend
                VStack(alignment: .leading, spacing: 14) {
                    let sortedData = distributionData.sorted { $0.count > $1.count }
                    let colors: [Color] = [TPDesign.celestialBlue, TPDesign.warmAmber, TPDesign.marineDeep, TPDesign.warmGold, TPDesign.leicaRed]
                    
                    let mainData = sortedData.prefix(3)
                    let moreData = sortedData.dropFirst(3)
                    
                    ForEach(0..<mainData.count, id: \.self) { index in
                        LegendRow(color: colors[index % colors.count], label: mainData[index].type.displayName, value: mainData[index].count)
                    }
                    
                    if !moreData.isEmpty {
                        DisclosureGroup {
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(0..<moreData.count, id: \.self) { index in
                                    LegendRow(color: colors[(index + 3) % colors.count], label: moreData[Array(moreData).index(moreData.startIndex, offsetBy: index)].type.displayName, value: moreData[Array(moreData).index(moreData.startIndex, offsetBy: index)].count)
                                }
                            }
                            .padding(.top, 12)
                        } label: {
                            Text(locKey: "footprint.more_types")
                                .font(TPDesign.captionFont())
                                .foregroundStyle(TPDesign.textTertiary)
                        }
                        .tint(TPDesign.textTertiary)
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
        .cinematicFadeIn(delay: 0.2)
    }

    struct LegendRow: View {
        let color: Color
        let label: String
        let value: Int
        
        var body: some View {
            HStack(spacing: 8) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                Text(label)
                    .font(TPDesign.bodyFont(14))
                    .foregroundStyle(TPDesign.textSecondary)
                Spacer()
                Text("\(value)")
                    .font(TPDesign.bodyFont(14).bold())
                    .foregroundStyle(TPDesign.textPrimary)
            }
        }
    }

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(locKey: "footprints.section.recent")
                .font(TPDesign.titleFont(20))
                .cinematicFadeIn(delay: 0.3)

            ForEach(Array(travels.prefix(3).enumerated()), id: \.element.id) { index, travel in
                NavigationLink(destination: TravelDetailView(travel: travel)) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(travel.name)
                                .font(TPDesign.bodyFont(18))
                                .foregroundStyle(TPDesign.textPrimary)
                            HStack(spacing: 6) {
                                Text(travel.startDate.formatted(.dateTime.year().month()))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(relativeDateString(from: travel.startDate))
                                    .font(.caption)
                                    .foregroundStyle(TPDesign.textTertiary)
                            }
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.tertiary)
                    }
                    .padding()
                    .contentShape(Rectangle()) // Ensure entire card is tappable
                    .glassCard(cornerRadius: 16)
                }
                .cinematicFadeIn(delay: Double(index) * 0.12 + 0.35)
            }
        }
    }

    private func relativeDateString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    var iconColor: Color = .tpAccent

    var body: some View {
        HStack(spacing: 12) {
            // Icon Ring (Compact)
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(iconColor)
            }
            .overlay(
                Circle()
                    .stroke(iconColor.opacity(0.2), lineWidth: 0.5)
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(TPDesign.titleFont(22))
                    .foregroundStyle(TPDesign.textPrimary)
                    .trackingMedium()
                Text(title)
                    .font(TPDesign.overline())
                    .foregroundStyle(TPDesign.textSecondary)
                    .trackingWide()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .glassCard(cornerRadius: TPDesign.radiusMedium)
        .shadowSmall()
    }
}

#Preview {
    FootprintReviewView()
}
