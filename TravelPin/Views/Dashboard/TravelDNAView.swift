import SwiftUI
import SwiftData

// MARK: - Travel DNA Card View

struct TravelDNAView: View {
    let dna: TravelDNA
    @Environment(\.dismiss) private var dismiss
    @State private var showShareSheet = false
    @State private var appeared = false

    var body: some View {
        ZStack {
            TPDesign.cinematicGradient
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header with avatar
                    headerSection
                        .padding(.top, 50)

                    // Type badge
                    typeBadge
                        .padding(.top, 20)

                    // Distribution charts
                    if !dna.spotTypeDistribution.isEmpty {
                        distributionSection
                            .padding(.top, 32)
                            .padding(.horizontal, 20)
                    }

                    // Stats grid
                    statsGrid
                        .padding(.top, 28)
                        .padding(.horizontal, 20)

                    // Personality tags
                    if !dna.personalityTags.isEmpty {
                        personalitySection
                            .padding(.top, 28)
                            .padding(.horizontal, 20)
                    }

                    // Favorite cities
                    if !dna.favoriteCities.isEmpty {
                        citiesSection
                            .padding(.top, 28)
                            .padding(.horizontal, 20)
                    }

                    // Travel motto
                    mottoSection
                        .padding(.top, 28)
                        .padding(.horizontal, 20)

                    // Actions
                    actionButtons
                        .padding(.top, 36)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 60)
                }
            }
        }
        .overlay(alignment: .topTrailing) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(20)
            }
        }
        .onAppear {
            withAnimation(TPDesign.cinemaReveal) {
                appeared = true
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(TPDesign.celestialBlue.opacity(0.2))
                    .frame(width: 100, height: 100)
                    .blur(radius: 20)

                Image(systemName: dna.travelerTypeIcon)
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(.white)
            }

            Text(locKey: "dna.title")
                .font(TPDesign.editorialSerif(32))
                .foregroundStyle(.white)
        }
    }

    private var typeBadge: some View {
        VStack(spacing: 6) {
            Text(dna.travelerType)
                .font(TPDesign.titleFont(24, weight: .bold))
                .foregroundStyle(.white)

            Text(dna.travelerTypeEN)
                .font(TPDesign.bodyFont(14, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))
                .tracking(2)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 28)
        .background(
            Capsule()
                .fill(.white.opacity(0.08))
                .overlay(Capsule().stroke(.white.opacity(0.15), lineWidth: 0.5))
        )
    }

    // MARK: - Distribution

    private var distributionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionLabel(title: "dna.section.preferences", icon: "chart.pie")

            // Travel type distribution
            if !dna.travelTypeDistribution.isEmpty {
                VStack(spacing: 8) {
                    ForEach(dna.travelTypeDistribution.prefix(3)) { ratio in
                        distributionBar(
                            label: ratio.type.displayName,
                            icon: ratio.type.icon,
                            percentage: ratio.percentage,
                            color: travelTypeColor(ratio.type)
                        )
                    }
                }
            }
        }
        .padding(20)
        .background(cardBackground)
    }

    private func distributionBar(label: String, icon: String, percentage: Int, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(color)
                .frame(width: 20)

            Text(label)
                .font(TPDesign.bodyFont(14, weight: .medium))
                .foregroundStyle(.white.opacity(0.8))
                .frame(width: 60, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.white.opacity(0.08))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(percentage) / 100)
                }
            }
            .frame(height: 8)

            Text("\(percentage)%")
                .font(TPDesign.captionFont())
                .foregroundStyle(.white.opacity(0.5))
                .frame(width: 36, alignment: .trailing)
        }
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            statCard(value: "\(dna.totalTrips)", label: "dna.stat.trips".localized, icon: "airplane")
            statCard(value: "\(dna.totalSpots)", label: "dna.stat.spots".localized, icon: "mappin")
            statCard(value: "\(dna.totalDays)", label: "dna.stat.days".localized, icon: "calendar")
            statCard(value: "\(dna.totalPhotos)", label: "dna.stat.photos".localized, icon: "camera")
        }
    }

    private func statCard(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(TPDesign.celestialBlue)

            Text(value)
                .font(TPDesign.titleFont(24, weight: .bold))
                .foregroundStyle(.white)

            Text(label)
                .font(TPDesign.captionFont())
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: TPDesign.radiusMedium)
                .fill(.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: TPDesign.radiusMedium)
                        .stroke(.white.opacity(0.08), lineWidth: 0.5)
                )
        )
    }

    // MARK: - Personality

    private var personalitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel(title: "dna.section.personality", icon: "brain.head.profile")

            FlowLayout(spacing: 8) {
                ForEach(dna.personalityTags, id: \.self) { tag in
                    Text(tag)
                        .font(TPDesign.bodyFont(13, weight: .semibold))
                        .foregroundStyle(TPDesign.celestialBlue)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(TPDesign.celestialBlue.opacity(0.12))
                        )
                }
            }
        }
        .padding(20)
        .background(cardBackground)
    }

    // MARK: - Cities

    private var citiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel(title: "dna.section.cities", icon: "building.2.crop.circle")

            HStack(spacing: 12) {
                ForEach(dna.favoriteCities, id: \.self) { city in
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(TPDesign.warmGold)
                        Text(city)
                            .font(TPDesign.bodyFont(14, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(.white.opacity(0.06))
                    )
                }
            }
        }
        .padding(20)
        .background(cardBackground)
    }

    // MARK: - Motto

    private var mottoSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "text.quote")
                .font(.system(size: 20, weight: .light))
                .foregroundStyle(TPDesign.warmGold)

            Text(dna.travelMotto)
                .font(TPDesign.editorialSerif(18))
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.horizontal, 16)
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(cardBackground)
    }

    // MARK: - Actions

    private var actionButtons: some View {
        VStack(spacing: 12) {
            ShareLink(
                item: "我的旅行 DNA：\(dna.travelerType) — TravelPin",
                subject: Text("旅行 DNA 分析报告"),
                message: Text("我是「\(dna.travelerType)」，已完成 \(dna.totalTrips) 次旅行，走过 \(dna.totalDays) 天旅程。来 TravelPin 发现你的旅行 DNA！")
            ) {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                    Text(locKey: "dna.action.share")
                }
                .font(TPDesign.bodyFont(15, weight: .bold))
                .foregroundStyle(TPDesign.deepNavy)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: TPDesign.radiusMedium)
                        .fill(TPDesign.accentGradient)
                )
            }

            Button {
                dismiss()
            } label: {
                Text(locKey: "dna.action.close")
                    .font(TPDesign.bodyFont(14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
    }

    // MARK: - Helpers

    private func sectionLabel(title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
            Text(locKey: title)
                .font(TPDesign.overline())
                .tracking(1)
        }
        .foregroundStyle(TPDesign.celestialBlue)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: TPDesign.radiusLarge)
            .fill(.white.opacity(0.06))
            .overlay(
                RoundedRectangle(cornerRadius: TPDesign.radiusLarge)
                    .stroke(.white.opacity(0.1), lineWidth: 0.5)
            )
    }

    private func travelTypeColor(_ type: TravelType) -> Color {
        switch type {
        case .tourism: return TPDesign.celestialBlue
        case .concert: return Color.purple
        case .chill: return TPDesign.warmGold
        case .business: return TPDesign.warmAmber
        case .other: return .green
        }
    }
}

// MARK: - DNA Quick Access Card (for Dashboard)

struct TravelDNACard: View {
    let dna: TravelDNA

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "dna")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(TPDesign.celestialBlue)
                Text(locKey: "dna.card.title")
                    .font(TPDesign.overline())
                    .tracking(1)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(TPDesign.textTertiary)
            }

            HStack(spacing: 12) {
                Image(systemName: dna.travelerTypeIcon)
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(TPDesign.celestialBlue)
                    .frame(width: 48, height: 48)
                    .background(TPDesign.celestialBlue.opacity(0.08))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(dna.travelerType)
                        .font(TPDesign.bodyFont(16, weight: .bold))
                        .foregroundStyle(TPDesign.textPrimary)

                    HStack(spacing: 8) {
                        Text("\(dna.totalTrips) 次旅行")
                        Text("·")
                        Text("\(dna.totalSpots) 个打卡")
                    }
                    .font(TPDesign.captionFont())
                    .foregroundStyle(TPDesign.textSecondary)
                }

                Spacer()

                if !dna.personalityTags.isEmpty {
                    Text(dna.personalityTags[0])
                        .font(TPDesign.bodyFont(12, weight: .bold))
                        .foregroundStyle(TPDesign.celestialBlue)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(TPDesign.celestialBlue.opacity(0.08))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: TPDesign.radiusLarge)
                .fill(TPDesign.surface1)
                .overlay(
                    RoundedRectangle(cornerRadius: TPDesign.radiusLarge)
                        .stroke(TPDesign.celestialBlue.opacity(0.1), lineWidth: 1)
                )
        )
        .shadowSmall()
    }
}
