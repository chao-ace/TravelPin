import SwiftUI
import SwiftData

// MARK: - Inspiration Plaza (Community Hub)

struct InspirationPlazaView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var social = SocialService.shared
    @State private var selectedTrip: PublishedTrip?
    @State private var selectedCategory: InspirationCategory = .featured

    var body: some View {
        NavigationStack {
            ZStack {
                TPDesign.background.ignoresSafeArea()

                if social.isLoading && social.publicTrips.isEmpty {
                    loadingState
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 0) {
                            headerSection
                            categoryPills
                            featuredEditorial
                            communityTripsGrid
                            collaborationSection
                            Spacer(minLength: 120)
                        }
                    }
                    .refreshable {
                        await social.fetchPublicTrips(category: selectedCategory.filterTag, refresh: true)
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: CollaborationInviteView()) {
                        Image(systemName: "person.2.circle")
                            .font(.title3)
                            .foregroundStyle(TPDesign.obsidian)
                    }
                }
            }
            .sheet(item: $selectedTrip) { trip in
                TripResonanceDetailView(trip: trip) {
                    remixTrip(trip)
                }
            }
        }
        .task {
            if !NetworkMonitor.shared.isConnected {
                ToastManager.shared.show(type: .warning, message: "common.error.network".localized)
            }
            await social.fetchPublicTrips()
        }
    }

    // MARK: - Loading State

    private var loadingState: some View {
        VStack(spacing: 20) {
            Spacer()
            ProgressView()
                .scaleEffect(1.2)
            Text(locKey: "inspiration.loading")
                .font(TPDesign.bodyFont(14))
                .foregroundStyle(TPDesign.textTertiary)
            Spacer()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(locKey: "inspiration.header.title")
                .font(TPDesign.editorialSerif(36))
                .foregroundStyle(TPDesign.obsidian)

            Text(locKey: "inspiration.header.subtitle")
                .font(TPDesign.bodyFont(15))
                .foregroundStyle(TPDesign.textSecondary)
                .trackingMedium()
        }
        .padding(.horizontal, 24)
        .padding(.top, 40)
        .padding(.bottom, 20)
        .cinematicFadeIn(delay: 0.1)
    }

    // MARK: - Category Pills

    private var categoryPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(InspirationCategory.allCases, id: \.self) { cat in
                    let isSelected = selectedCategory == cat
                    Button {
                        TPHaptic.selection()
                        withAnimation(TPDesign.springDefault) {
                            selectedCategory = cat
                        }
                        Task {
                            await social.fetchPublicTrips(category: cat.filterTag)
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: cat.icon)
                                .font(.system(size: 12, weight: .bold))
                            Text(cat.displayName)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .foregroundStyle(isSelected ? .white : TPDesign.textSecondary)
                        .background {
                            if isSelected {
                                Capsule().fill(TPDesign.accentGradient)
                            } else {
                                Capsule().fill(TPDesign.secondaryBackground)
                            }
                        }
                        .overlay(Capsule().stroke(isSelected ? Color.clear : TPDesign.divider, lineWidth: 1))
                    }
                    .buttonStyle(CinematicButtonStyle())
                }
            }
            .padding(.horizontal, 24)
        }
        .padding(.bottom, 20)
        .cinematicFadeIn(delay: 0.15)
    }

    // MARK: - Featured Editorial

    private var featuredEditorial: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(locKey: "inspiration.section.featured")
                    .font(TPDesign.editorialSerif(22))
                    .foregroundStyle(TPDesign.obsidian)
                Spacer()
                Image(systemName: "sparkles")
                    .foregroundStyle(TPDesign.warmGold)
            }

            if let featuredTrip = social.publicTrips.first(where: { $0.isFeatured }) ?? social.publicTrips.first {
                Button {
                    TPHaptic.mechanicalPress()
                    selectedTrip = featuredTrip
                } label: {
                    featuredCard(trip: featuredTrip)
                }
                .buttonStyle(CinematicButtonStyle())
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
        .cinematicFadeIn(delay: 0.2)
    }

    private func featuredCard(trip: PublishedTrip) -> some View {
        ZStack(alignment: .bottomLeading) {
            // Background
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(cardGradient(for: trip.travelType))
                    .frame(height: 220)

                Image(systemName: trip.travelType.icon)
                    .font(.system(size: 80, weight: .ultraLight))
                    .foregroundStyle(.white.opacity(0.08))
                    .offset(x: 80, y: -30)
            }

            // Content
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 11, weight: .bold))
                    Text(locKey: "inspiration.badge.featured")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundStyle(TPDesign.warmGold)
                .tracking(1)

                Text(trip.title)
                    .font(.system(size: 28, weight: .black, design: .serif))
                    .foregroundStyle(.white)

                HStack(spacing: 16) {
                    Label("\(trip.durationDays) \("common.days".localized)", systemImage: "calendar")
                    Label(trip.travelType.displayName, systemImage: trip.travelType.icon)
                    Label("\(trip.likeCount) \("inspiration.stat.likes".localized)", systemImage: "heart.fill")
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))

                // Author
                HStack(spacing: 6) {
                    Image(systemName: trip.authorAvatarSymbol)
                        .font(.system(size: 12))
                    Text(trip.authorName)
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(.white.opacity(0.5))
            }
            .padding(24)

            // Remix badge
            VStack {
                HStack {
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 10, weight: .bold))
                        Text("Remix")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(TPDesign.secondaryBackground.opacity(0.15)))
                    .overlay(Capsule().stroke(TPDesign.obsidian.opacity(0.2), lineWidth: 0.5))
                }
                Spacer()
            }
            .padding(16)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(.white.opacity(0.15), lineWidth: 0.5)
        )
        .shadowLarge()
    }

    // MARK: - Community Grid

    private var communityTripsGrid: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text(locKey: "inspiration.section.community")
                    .font(TPDesign.editorialSerif(22))
                    .foregroundStyle(TPDesign.obsidian)
                Spacer()
                Text("\(social.publicTrips.count) \("nav.journeys".localized)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(TPDesign.textTertiary)
            }
            .padding(.horizontal, 24)

            let trips = filteredTrips
            let columns = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]

            if trips.isEmpty {
                emptyCommunityState
            } else {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(Array(trips.enumerated()), id: \.element.id) { index, trip in
                        Button {
                            TPHaptic.mechanicalPress()
                            selectedTrip = trip
                        } label: {
                            communityCard(trip: trip)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .cinematicFadeIn(delay: 0.2 + Double(index) * 0.05)
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }

    private var emptyCommunityState: some View {
        VStack(spacing: 16) {
            Image(systemName: "globe.americas")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(TPDesign.textTertiary)
            Text(locKey: "inspiration.empty.title")
                .font(TPDesign.bodyFont(15))
                .foregroundStyle(TPDesign.textTertiary)
            Text(locKey: "inspiration.empty.subtitle")
                .font(TPDesign.bodyFont(13))
                .foregroundStyle(TPDesign.textTertiary.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var filteredTrips: [PublishedTrip] {
        let trips: [PublishedTrip]
        switch selectedCategory {
        case .featured, .all:
            trips = social.publicTrips
        case .nature:
            trips = social.publicTrips.filter { $0.categoryTags.contains("inspiration.tag.nature".localized) || $0.travelType == .chill }
        case .culture:
            trips = social.publicTrips.filter { $0.categoryTags.contains("inspiration.tag.culture".localized) || $0.travelType == .tourism }
        case .food:
            trips = social.publicTrips.filter { $0.categoryTags.contains("inspiration.tag.food".localized) }
        }
        // Skip the featured one in the grid (it's shown above)
        if let featured = trips.first(where: { $0.isFeatured }) {
            return trips.filter { $0.id != featured.id }
        }
        return trips
    }

    private func communityCard(trip: PublishedTrip) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 20)
                    .fill(cardGradient(for: trip.travelType))
                    .frame(height: 140)
                    .overlay(
                        Image(systemName: trip.travelType.icon)
                            .font(.system(size: 28))
                            .foregroundStyle(.white.opacity(0.2))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(.white.opacity(0.12), lineWidth: 0.5)
                    )

                // Like count badge
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 9, weight: .black))
                    Text("\(trip.likeCount)")
                        .font(.system(size: 9, weight: .bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(TPDesign.obsidian.opacity(0.3)))
                .padding(10)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(trip.title)
                    .font(TPDesign.editorialSerif(16))
                    .foregroundStyle(TPDesign.obsidian)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text("\(trip.durationDays) \("common.days".localized)")
                    Text("\u{00B7}")
                    Text(trip.authorName)
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(TPDesign.textSecondary)
            }
            .padding(.horizontal, 4)
        }
    }

    private func cardGradient(for type: TravelType) -> LinearGradient {
        switch type {
        case .tourism:  return LinearGradient(colors: [TPDesign.deepNavy, TPDesign.midnightTeal], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .concert:  return LinearGradient(colors: [TPDesign.marineDeep, TPDesign.celestialBlue.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .chill:    return LinearGradient(colors: [TPDesign.warmAmber.opacity(0.6), TPDesign.warmGold], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .business: return LinearGradient(colors: [TPDesign.obsidian, TPDesign.obsidian.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .other:    return LinearGradient(colors: [TPDesign.marineDeep.opacity(0.5), TPDesign.deepNavy], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    // MARK: - Collaboration Section

    private var collaborationSection: some View {
        VStack(spacing: 16) {
            NavigationLink(destination: CollaborationInviteView()) {
                collabCard
            }
            .buttonStyle(PlainButtonStyle())

            developingCard(
                icon: "arrow.triangle.branch",
                title: "inspiration.reroute.title".localized,
                desc: "inspiration.reroute.desc".localized,
                color: TPDesign.celestialBlue
            )
        }
        .padding(.horizontal, 24)
        .padding(.top, 32)
    }

    private var collabCard: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(TPDesign.warmGold.opacity(0.08))
                    .frame(width: 52, height: 52)
                Image(systemName: "person.2.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(TPDesign.warmGold)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(locKey: "inspiration.collab.title")
                        .font(TPDesign.bodyFont(16, weight: .bold))
                        .foregroundStyle(TPDesign.obsidian)

                    Text(locKey: "inspiration.badge.new")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.tpAccent))
                }

                Text(locKey: "inspiration.collab.desc")
                    .font(TPDesign.bodyFont(13))
                    .foregroundStyle(TPDesign.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(TPDesign.textTertiary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(TPDesign.secondaryBackground.opacity(0.6))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(TPDesign.divider, lineWidth: 0.5))
        )
        .shadowSmall()
    }

    private func developingCard(icon: String, title: String, desc: String, color: Color) -> some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(color.opacity(0.08))
                    .frame(width: 52, height: 52)
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(TPDesign.bodyFont(16, weight: .bold))
                        .foregroundStyle(TPDesign.obsidian)

                    Text(locKey: "inspiration.badge.developing")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(TPDesign.warmAmber))
                }

                Text(desc)
                    .font(TPDesign.bodyFont(13))
                    .foregroundStyle(TPDesign.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(TPDesign.textTertiary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(TPDesign.secondaryBackground.opacity(0.6))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(TPDesign.divider, lineWidth: 0.5))
        )
        .shadowSmall()
    }

    // MARK: - Actions

    private func remixTrip(_ published: PublishedTrip) {
        // Create a local Travel from the published snapshot
        let travel = Travel(
            name: published.title,
            endDate: Date().addingTimeInterval(86400 * Double(max(1, published.durationDays - 1))),
            status: TravelStatus.planning.rawValue,
            type: published.travelTypeRaw
        )

        // Restore itinerary + spot structure from snapshot
        if let snapshot = published.decodedSnapshot {
            for itSnap in snapshot.itineraries {
                let itinerary = Itinerary(day: itSnap.day, origin: itSnap.origin, destination: itSnap.destination)
                itinerary.travel = travel
                travel.itineraries.append(itinerary)
            }
            for spSnap in snapshot.spots {
                let spot = Spot(name: spSnap.name, type: spSnap.typeRaw, notes: spSnap.notes)
                spot.travel = travel
                if let lat = spSnap.latitude, let lng = spSnap.longitude {
                    spot.latitude = lat
                    spot.longitude = lng
                }
                travel.spots.append(spot)
            }
        }

        modelContext.insert(travel)
        try? modelContext.save()

        TPHaptic.notification(.success)
        ToastManager.shared.show(type: .success, message: "inspiration.remix_success".localized)
    }
}

// MARK: - Inspiration Category

enum InspirationCategory: CaseIterable {
    case featured
    case nature
    case culture
    case food
    case all

    var displayName: String {
        switch self {
        case .featured: return "inspiration.cat.featured".localized
        case .nature:   return "inspiration.cat.nature".localized
        case .culture:  return "inspiration.cat.culture".localized
        case .food:     return "inspiration.cat.food".localized
        case .all:      return "inspiration.cat.all".localized
        }
    }

    var icon: String {
        switch self {
        case .featured: return "star.fill"
        case .nature:   return "leaf.fill"
        case .culture:  return "building.columns.fill"
        case .food:     return "fork.knife"
        case .all:      return "square.grid.2x2"
        }
    }

    var filterTag: String? {
        switch self {
        case .featured, .all: return nil
        case .nature:   return "inspiration.tag.nature".localized
        case .culture:  return "inspiration.tag.culture".localized
        case .food:     return "inspiration.tag.food".localized
        }
    }
}

#Preview {
    InspirationPlazaView()
}
