import SwiftUI

// MARK: - Share Card Generator

/// Generates shareable travel cards for social media (小红书, 朋友圈, etc.)
struct ShareCardGenerator {

    // MARK: - Travel Summary Card

    @MainActor
    static func generateTravelCard(travel: Travel) -> some View {
        TravelShareCard(travel: travel)
    }

    // MARK: - DNA Card

    @MainActor
    static func generateDNACard(dna: TravelDNA) -> some View {
        DNAShareCard(dna: dna)
    }
}

// MARK: - Travel Share Card

struct TravelShareCard: View {
    let travel: Travel

    private let cardWidth: CGFloat = 375
    private let cardHeight: CGFloat = 500 // 小红书 3:4 ratio

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [TPDesign.deepNavy, TPDesign.midnightTeal, TPDesign.celestialBlue.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Decorative elements
            VStack {
                Spacer()

                Image(systemName: travel.type.icon)
                    .font(.system(size: 120, weight: .ultraLight))
                    .foregroundStyle(.white.opacity(0.06))
                    .offset(x: 60, y: -40)
            }

            VStack(alignment: .leading, spacing: 0) {
                // Brand header
                HStack(spacing: 8) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 16, weight: .bold))
                    Text("TravelPin")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .tracking(2)
                }
                .foregroundStyle(.white.opacity(0.6))
                .padding(.top, 32)
                .padding(.horizontal, 28)

                Spacer(minLength: 0)

                // Travel name
                Text(travel.name)
                    .font(.system(size: 36, weight: .black, design: .serif))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .padding(.horizontal, 28)

                // Date range
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.system(size: 12))
                    Text("\(travel.startDate.formatted(.dateTime.month().day())) — \(travel.endDate.formatted(.dateTime.month().day().year()))")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundStyle(.white.opacity(0.7))
                .padding(.top, 12)
                .padding(.horizontal, 28)

                // Stats row
                HStack(spacing: 20) {
                    statBadge(value: "\(travel.itineraries.count)", label: "天", icon: "calendar")
                    statBadge(value: "\(travel.spots.count)", label: "打卡", icon: "mappin")
                    statBadge(value: "\(travel.spots.flatMap { $0.photos }.count)", label: "照片", icon: "camera")
                }
                .padding(.top, 20)
                .padding(.horizontal, 28)

                // Type badge
                HStack(spacing: 8) {
                    Image(systemName: travel.type.icon)
                        .font(.system(size: 11, weight: .bold))
                    Text(travel.type.displayName)
                }
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(.white.opacity(0.15)))
                .padding(.top, 16)
                .padding(.horizontal, 28)

                // Tagline
                Text("去探索，去体验，去存在")
                    .font(.system(size: 11, weight: .medium, design: .serif))
                    .foregroundStyle(.white.opacity(0.4))
                    .tracking(4)
                    .padding(.top, 20)
                    .padding(.bottom, 28)
                    .padding(.horizontal, 28)
            }
        }
        .frame(width: cardWidth, height: cardHeight)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private func statBadge(value: String, label: String, icon: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(value)
                .font(.system(size: 14, weight: .black, design: .rounded))
            Text(label)
                .font(.system(size: 11))
        }
        .foregroundStyle(.white.opacity(0.8))
    }
}

// MARK: - DNA Share Card

struct DNAShareCard: View {
    let dna: TravelDNA

    private let cardWidth: CGFloat = 375
    private let cardHeight: CGFloat = 500

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [TPDesign.obsidian, TPDesign.deepNavy, TPDesign.midnightTeal],
                startPoint: .top,
                endPoint: .bottom
            )

            // Decorative circle
            Circle()
                .fill(TPDesign.celestialBlue.opacity(0.05))
                .frame(width: 300, height: 300)
                .blur(radius: 40)
                .offset(x: 60, y: -80)

            VStack(spacing: 0) {
                // Header
                HStack(spacing: 8) {
                    Image(systemName: "dna")
                        .font(.system(size: 14, weight: .bold))
                    Text("TRAVEL DNA")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .tracking(3)
                }
                .foregroundStyle(TPDesign.celestialBlue)
                .padding(.top, 32)

                // Type icon
                Image(systemName: dna.travelerTypeIcon)
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(.white)
                    .padding(.top, 20)

                // Traveler type
                Text(dna.travelerType)
                    .font(.system(size: 28, weight: .black, design: .serif))
                    .foregroundStyle(.white)
                    .padding(.top, 12)

                Text(dna.travelerTypeEN)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.4))
                    .tracking(2)

                // Stats
                HStack(spacing: 24) {
                    dnaStat(value: "\(dna.totalTrips)", label: "旅程")
                    dnaStat(value: "\(dna.totalSpots)", label: "打卡")
                    dnaStat(value: "\(dna.totalDays)", label: "天数")
                }
                .padding(.top, 24)

                // Personality tags
                if !dna.personalityTags.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(dna.personalityTags.prefix(3), id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(TPDesign.celestialBlue)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(TPDesign.celestialBlue.opacity(0.12)))
                        }
                    }
                    .padding(.top, 20)
                }

                // Motto
                Text(dna.travelMotto)
                    .font(.system(size: 13, weight: .regular, design: .serif))
                    .foregroundStyle(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
                    .padding(.top, 20)

                Spacer(minLength: 0)

                // Brand footer
                HStack(spacing: 6) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 10))
                    Text("TravelPin")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                }
                .foregroundStyle(.white.opacity(0.3))
                .padding(.bottom, 24)
            }
        }
        .frame(width: cardWidth, height: cardHeight)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private func dnaStat(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.white.opacity(0.4))
        }
    }
}
