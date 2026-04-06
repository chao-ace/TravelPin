import SwiftUI
import SwiftData

struct TravelDetailView: View {
    @Bindable var travel: Travel
    @Environment(\.modelContext) private var modelContext

    @State private var showingAddItinerary = false
    @State private var showingAddSpot = false
    @State private var showingAIReview = false
    @ObservedObject var realtime = RealtimeManager.shared

    @Namespace private var animation
    @State private var selectedSpot: Spot? = nil
    @ObservedObject var intelligence = IntelligenceService.shared

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    // Intelligence Advice Banner
                    IntelligenceBanner(travel: travel)
                        .padding(.top, 10)
                        .background(Color.tpSurface.opacity(0.1))



                    // Header with Parallax IMAX Title
                    GeometryReader { geo in
                        let scrollOffset = geo.frame(in: .global).minY
                        VStack(alignment: .leading, spacing: 12) {
                            Text(travel.name)
                                .font(TPDesign.cinematicTitle(48))
                                .offset(y: scrollOffset > 0 ? -scrollOffset * 0.4 : 0) // Parallax
                                .blur(radius: scrollOffset > 0 ? scrollOffset * 0.02 : 0)

                            HStack {
                                Label(travel.status.displayName, systemImage: "circle.fill")
                                    .foregroundStyle(Color.statusColor(for: travel.status))
                                Spacer()
                                Text("\(travel.startDate.formatted(.dateTime.day().month())) - \(travel.endDate.formatted(.dateTime.day().month()))")
                                    .foregroundStyle(.secondary)
                            }
                            .font(TPDesign.bodyFont(18))
                        }
                    }
                    .frame(height: 120)
                    .padding(.horizontal)
                    .onAppear {
                        intelligence.performVibeCheck(for: travel)
                    }

                    // Tabs / Sections
                    VStack(spacing: 48) {
                        itinerarySection
                        spotArchiveSection
                        luggageMiniSection
                    }
                    .padding(.bottom, 60)
                }
            }
            .blur(radius: selectedSpot != nil ? 10 : 0) // Focus Pull when card expands

            // Full Screen Immersive Expansion Overlay
            if let spot = selectedSpot {
                ImmersiveSpotDetailView(spot: spot, namespace: animation) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        selectedSpot = nil
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                HStack(spacing: 12) {
                    collaboratorBar
                    
                    if intelligence.activeRecommendation != nil {
                        Image(systemName: "wand.and.stars.inverse")
                            .foregroundStyle(Color.tpAccent)
                            .symbolEffect(.pulse)
                    }
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                menuButton
            }
        }
    }

    private var collaboratorBar: some View {
        HStack(spacing: -8) { // Overlapping circles
            ForEach(Array(realtime.onlineUsers.keys), id: \.self) { userID in
                LetterAvatarView(name: realtime.onlineUsers[userID] ?? "U")
                    .frame(width: 34, height: 34)
                    .background(Color.tpSurface)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
            }

            if realtime.onlineUsers.isEmpty {
                Image(systemName: "person.2.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(8)
                    .background(Color.tpSurface)
                    .clipShape(Circle())
            }
        }
    }

    private var menuButton: some View {
        Menu {
            Button(action: { showingAddItinerary.toggle() }) {
                Label("detail.menu.add_day".localized, systemImage: "calendar.badge.plus")
            }
            Button(action: { showingAddSpot.toggle() }) {
                Label("detail.menu.add_spot".localized, systemImage: "mappin.and.ellipse")
            }
            Divider()
            NavigationLink(destination: TravelMapView(travel: travel)) {
                Label("detail.menu.explore_map".localized, systemImage: "map")
            }
            Button(action: { showingAIReview.toggle() }) {
                Label("detail.menu.ai_review".localized, systemImage: "wand.and.stars")
            }
            NavigationLink(destination: TripPosterView(travel: travel)) {
                Label("detail.menu.trip_poster".localized, systemImage: "doc.richtext")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.title2)
                .foregroundStyle(Color.tpAccent)
        }
    }

    private var itinerarySection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(locKey: "detail.itinerary.title")
                .font(TPDesign.titleFont(24))
                .padding(.horizontal)

            if travel.itineraries.isEmpty {
                Text(locKey: "detail.itinerary.empty")
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            } else {
                ForEach(travel.itineraries.sorted(by: { $0.day < $1.day })) { itinerary in
                    ItineraryRow(itinerary: itinerary)
                }
            }
        }
    }

    private var spotArchiveSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(locKey: "detail.archive.title")
                .font(TPDesign.titleFont(24))
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 24) {
                    ForEach(travel.spots) { spot in
                        SpotHighlightCard(spot: spot, namespace: animation) {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                selectedSpot = spot
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private var luggageMiniSection: some View {
        NavigationLink(destination: LuggageView(travel: travel)) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(locKey: "detail.packing.title")
                        .font(TPDesign.titleFont(22))
                    Text("\(travel.luggageItems.filter { $0.isChecked }.count)/\(travel.luggageItems.count) \("detail.packing.prepared".localized)")
                        .font(TPDesign.bodyFont())
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .glassCard()
            .padding(.horizontal)
        }
        .buttonStyle(.plain)
    }
}

struct LetterAvatarView: View {
    let name: String

    var body: some View {
        Text(String(name.prefix(1)).uppercased())
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 34, height: 34)
            .background(Color.tpAccent)
            .clipShape(Circle())
    }
}

struct ItineraryRow: View {
    let itinerary: Itinerary

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack {
                Text("D\(itinerary.day)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(8)
                    .background(Color.tpAccent.opacity(0.1))
                    .clipShape(Circle())

                Rectangle()
                    .fill(.quaternary)
                    .frame(width: 2)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("\(itinerary.origin) → \(itinerary.destination)")
                    .font(TPDesign.titleFont(20))

                ForEach(itinerary.spots) { spot in
                    Label(spot.name, systemImage: spot.type.icon)
                        .font(TPDesign.bodyFont())
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.bottom, 24)
        }
        .padding(.horizontal)
    }
}

struct SpotHighlightCard: View {
    let spot: Spot
    var namespace: Namespace.ID
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottomLeading) {
                // Background Image (2.35:1)
                Group {
                    if let firstPhotoData = spot.photoData.first, let uiImage = UIImage(data: firstPhotoData) {
                        Image(uiImage: uiImage)
                            .resizable()
                    } else if let snapshotData = spot.mapSnapshot, let uiImage = UIImage(data: snapshotData) {
                        Image(uiImage: uiImage)
                            .resizable()
                    } else {
                        Rectangle()
                            .fill(Color.tpAccent.opacity(0.1))
                            .overlay(Image(systemName: "photo").foregroundStyle(Color.tpAccent))
                    }
                }
                .matchedGeometryEffect(id: "image_\(spot.id)", in: namespace)
                .aspectRatio(TPDesign.anamorphicRatio, contentMode: .fill)
                .frame(width: 280, height: 280 / TPDesign.anamorphicRatio)
                .clipShape(RoundedRectangle(cornerRadius: 24))

                // Narrative Overlay
                LinearGradient(colors: [.black.opacity(0.6), .clear], startPoint: .bottom, endPoint: .center)
                    .clipShape(RoundedRectangle(cornerRadius: 24))

                VStack(alignment: .leading, spacing: 4) {
                    Text(spot.name)
                        .font(TPDesign.cinematicTitle(24))
                        .foregroundStyle(.white)
                    Text(spot.type.displayName)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))
                        .tracking(2)
                }
                .padding(16)
                .matchedGeometryEffect(id: "title_\(spot.id)", in: namespace)
            }
        }
        .buttonStyle(.plain)
    }
}

struct ImmersiveSpotDetailView: View {
    let spot: Spot
    var namespace: Namespace.ID
    let onClose: () -> Void

    @State private var currentPhotoIndex: Int = 0

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()
                .opacity(0.9)

            ScrollView {
                VStack(spacing: 0) {
                    // Hero Image with photo pagination
                    TabView(selection: $currentPhotoIndex) {
                        ForEach(Array(spot.photoData.enumerated()), id: \.offset) { index, data in
                            if let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .tag(index)
                            }
                        }
                    }
                    .matchedGeometryEffect(id: "image_\(spot.id)", in: namespace)
                    .aspectRatio(TPDesign.anamorphicRatio, contentMode: .fill)
                    .frame(maxWidth: .infinity)
                    .tabViewStyle(.page)

                    // Content
                    VStack(alignment: .leading, spacing: 20) {
                        // Title & Type
                        Text(spot.name)
                            .font(TPDesign.cinematicTitle(40))
                            .foregroundStyle(.white)
                            .matchedGeometryEffect(id: "title_\(spot.id)", in: namespace)

                        HStack(spacing: 12) {
                            Label(spot.type.displayName, systemImage: spot.type.icon)
                                .font(.subheadline.bold())
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.tpAccent.opacity(0.2))
                                .foregroundStyle(Color.tpAccent)
                                .clipShape(Capsule())

                            if let rating = spot.rating {
                                HStack(spacing: 2) {
                                    ForEach(1...5, id: \.self) { star in
                                        Image(systemName: star <= rating ? "star.fill" : "star")
                                            .font(.caption)
                                            .foregroundStyle(.yellow)
                                    }
                                }
                            }

                            if let cost = spot.cost {
                                Label("¥\(Int(cost))", systemImage: "yensign.circle")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.orange)
                            }
                        }

                        // Address
                        if let address = spot.address, !address.isEmpty {
                            Label(address, systemImage: "mappin.circle")
                                .font(TPDesign.bodyFont(16))
                                .foregroundStyle(.white.opacity(0.6))
                        }

                        // Notes
                        if !spot.notes.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(locKey: "detail.atmosphere")
                                    .font(TPDesign.titleFont(20))
                                    .foregroundStyle(Color.tpAccent)

                                Text(spot.notes)
                                    .font(TPDesign.bodyFont(17))
                                    .foregroundStyle(.white.opacity(0.8))
                                    .lineSpacing(8)
                            }
                            .padding(.top, 8)
                        }

                        // Tags
                        if !spot.tags.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(spot.tags, id: \.self) { tag in
                                        Text("#\(tag)")
                                            .font(.caption.bold())
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(.white.opacity(0.1))
                                            .foregroundStyle(.white.opacity(0.7))
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }

                        // Visit Duration
                        if let duration = spot.visitDuration {
                            Label("\(duration) min", systemImage: "clock")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.5))
                        }
                    }
                    .padding(24)
                }
            }

            // Close Button
            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(24)
            }
        }
        .transition(.asymmetric(insertion: .identity, removal: .opacity))
    }
}
