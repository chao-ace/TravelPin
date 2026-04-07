import SwiftUI
import SwiftData

// MARK: - Inspiration Plaza (Community Hub)

struct InspirationPlazaView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showingSuccessToast = false
    @State private var selectedTrip: Travel?
    @State private var selectedCategory: InspirationCategory = .featured

    private let publicTrips = MockDataCenter.getPublicTrips()

    var body: some View {
        NavigationStack {
            ZStack {
                TPDesign.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        headerSection
                        categoryPills
                        featuredEditorial
                        communityTripsGrid
                        developingSection
                        Spacer(minLength: 120)
                    }
                }

                // Toast
                if showingSuccessToast {
                    VStack {
                        Spacer()
                        toastView
                    }
                    .ignoresSafeArea()
                    .zIndex(10)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedTrip) { trip in
                TripResonanceDetailView(travel: trip) {
                    remixTrip(trip)
                }
            }
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
                                Capsule().fill(Color.white)
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

    // MARK: - Featured Editorial (Curated)

    private var featuredEditorial: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("编辑精选")
                    .font(TPDesign.editorialSerif(22))
                    .foregroundStyle(TPDesign.obsidian)
                Spacer()
                Image(systemName: "sparkles")
                    .foregroundStyle(TPDesign.warmGold)
            }

            if let featuredTrip = publicTrips.first {
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

    private func featuredCard(trip: Travel) -> some View {
        ZStack(alignment: .bottomLeading) {
            // Background
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [TPDesign.deepNavy, TPDesign.midnightTeal],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 220)

                // Decorative icon
                Image(systemName: trip.type.icon)
                    .font(.system(size: 80, weight: .ultraLight))
                    .foregroundStyle(.white.opacity(0.08))
                    .offset(x: 80, y: -30)
            }

            // Content
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 11, weight: .bold))
                    Text("精选推荐")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundStyle(TPDesign.warmGold)
                .tracking(1)

                Text(trip.name)
                    .font(.system(size: 28, weight: .black, design: .serif))
                    .foregroundStyle(.white)

                HStack(spacing: 16) {
                    Label("\(trip.durationDays) 天", systemImage: "calendar")
                    Label("\(trip.spots.count) 处足迹", systemImage: "mappin")
                    Label(trip.type.displayName, systemImage: trip.type.icon)
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))
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
                    .background(Capsule().fill(Color.white.opacity(0.15)))
                    .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 0.5))
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
            Text("社区灵感")
                .font(TPDesign.editorialSerif(22))
                .foregroundStyle(TPDesign.obsidian)
                .padding(.horizontal, 24)

            let trips = filteredTrips
            let columns = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]

            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(Array(trips.enumerated()), id: \.offset) { index, trip in
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

    private var filteredTrips: [Travel] {
        switch selectedCategory {
        case .featured, .all:
            return publicTrips
        case .nature:
            return publicTrips.filter { $0.type == .chill || $0.type == .tourism }
        case .culture:
            return publicTrips.filter { $0.type == .tourism }
        case .food:
            return publicTrips.filter { $0.spots.contains { $0.type == .food } }
        }
    }

    private func communityCard(trip: Travel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 20)
                    .fill(cardGradient(for: trip.type))
                    .frame(height: 140)
                    .overlay(
                        Image(systemName: trip.type.icon)
                            .font(.system(size: 28))
                            .foregroundStyle(.white.opacity(0.2))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(.white.opacity(0.12), lineWidth: 0.5)
                    )

                // Remix badge
                Image(systemName: "sparkles")
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(.white)
                    .padding(6)
                    .background(Circle().fill(TPDesign.accentGradient).shadowSmall())
                    .padding(10)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(trip.name)
                    .font(TPDesign.editorialSerif(16))
                    .foregroundStyle(TPDesign.obsidian)
                    .lineLimit(1)

                Text("\(trip.durationDays) 天 · \(trip.spots.count) 处足迹")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(TPDesign.textSecondary)
            }
            .padding(.horizontal, 4)
        }
    }

    private func cardGradient(for type: TravelType) -> LinearGradient {
        switch type {
        case .tourism: return LinearGradient(colors: [TPDesign.deepNavy, TPDesign.midnightTeal], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .concert: return LinearGradient(colors: [TPDesign.marineDeep, TPDesign.celestialBlue.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .chill: return LinearGradient(colors: [TPDesign.warmAmber.opacity(0.6), TPDesign.warmGold], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .business: return LinearGradient(colors: [TPDesign.obsidian, TPDesign.obsidian.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .other: return LinearGradient(colors: [TPDesign.marineDeep.opacity(0.5), TPDesign.deepNavy], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    // MARK: - Developing Section (Dynamic Rerouting + Collaboration)

    private var developingSection: some View {
        VStack(spacing: 16) {
            developingCard(
                icon: "arrow.triangle.branch",
                title: "动态重路由",
                desc: "AI 实时感知天气与体力，智能调整行程路线",
                color: TPDesign.celestialBlue
            )

            developingCard(
                icon: "person.2.fill",
                title: "同行协作",
                desc: "邀请旅伴共同编辑行程，实时同步足迹",
                color: TPDesign.warmGold
            )
        }
        .padding(.horizontal, 24)
        .padding(.top, 32)
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

                    Text("开发中")
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
                .fill(Color.white.opacity(0.6))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(TPDesign.divider, lineWidth: 0.5))
        )
        .shadowSmall()
    }

    // MARK: - Toast

    private var toastView: some View {
        Text("inspiration.remix_success".localized)
            .font(TPDesign.bodyFont(14))
            .fontWeight(.bold)
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(TPDesign.obsidian)
            .clipShape(Capsule())
            .shadowFloating()
            .padding(.bottom, 120)
            .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Actions

    private func remixTrip(_ original: Travel) {
        let copy = MockDataCenter.deepClone(travel: original)
        modelContext.insert(copy)
        try? modelContext.save()

        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            showingSuccessToast = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showingSuccessToast = false }
        }
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
        case .featured: return "精选"
        case .nature: return "自然风光"
        case .culture: return "人文探索"
        case .food: return "美食之旅"
        case .all: return "全部"
        }
    }

    var icon: String {
        switch self {
        case .featured: return "star.fill"
        case .nature: return "leaf.fill"
        case .culture: return "building.columns.fill"
        case .food: return "fork.knife"
        case .all: return "square.grid.2x2"
        }
    }
}

#Preview {
    InspirationPlazaView()
}
