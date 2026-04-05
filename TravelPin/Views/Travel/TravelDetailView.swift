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

                    // Top Action Bar & Collaborators
                    HStack {
                        collaboratorBar
                        Spacer()
                        
                        if intelligence.activeRecommendation != nil {
                            // Intelligence Pulse Indicator (Magic Wand)
                            ZStack {
                                Circle().fill(Color.tpAccent.opacity(0.2)).frame(width: 44, height: 44)
                                    .scaleEffect(1.2)
                                    .blur(radius: 4)
                                Image(systemName: "wand.and.stars.inverse")
                                    .foregroundStyle(Color.tpAccent)
                            }
                            .transition(.scale)
                        }
                        
                        menuButton
                    }
                    .padding(.horizontal)

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
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(action: { showingAddItinerary.toggle() }) {
                        Label("Add Itinerary", systemImage: "calendar.badge.plus")
                    }
                    Button(action: { showingAddSpot.toggle() }) {
                        Label("Add Spot", systemImage: "mappin.and.ellipse")
                    }
                    NavigationLink(destination: TravelMapView(travel: travel)) {
                        Label("Explore Map", systemImage: "map")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title2)
                        .foregroundStyle(Color.tpAccent)
                }
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
                Label("Add Day", systemImage: "calendar.badge.plus")
            }
            Button(action: { showingAddSpot.toggle() }) {
                Label("Add Spot", systemImage: "mappin.and.ellipse")
            }
            Divider()
            NavigationLink(destination: TravelMapView(travel: travel)) {
                Label("Explore Map", systemImage: "map")
            }
            Button(action: { showingAIReview.toggle() }) {
                Label("AI Review", systemImage: "wand.and.stars")
            }
            NavigationLink(destination: TripPosterView(travel: travel)) {
                Label("Trip Poster", systemImage: "doc.richtext")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.title2)
                .foregroundStyle(Color.tpAccent)
        }
    }

    private var itinerarySection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("The Itinerary")
                .font(TPDesign.titleFont(24))
                .padding(.horizontal)

            if travel.itineraries.isEmpty {
                Text("No daily plans yet.")
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
            Text("Highlights & Archive")
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
                    Text("Packing Matrix")
                        .font(TPDesign.titleFont(22))
                    Text("\(travel.luggageItems.filter { $0.isChecked }.count)/\(travel.luggageItems.count) Prepared")
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

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()
                .opacity(0.9)

            VStack {
                // Immersive Header Image
                Group {
                    if let firstPhotoData = spot.photoData.first, let uiImage = UIImage(data: firstPhotoData) {
                        Image(uiImage: uiImage)
                            .resizable()
                    } else if let snapshotData = spot.mapSnapshot, let uiImage = UIImage(data: snapshotData) {
                        Image(uiImage: uiImage)
                            .resizable()
                    } else {
                        Rectangle().fill(Color.tpAccent.opacity(0.1))
                    }
                }
                .matchedGeometryEffect(id: "image_\(spot.id)", in: namespace)
                .aspectRatio(TPDesign.anamorphicRatio, contentMode: .fill)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 0))

                // Detailed Content (Fade in)
                VStack(alignment: .leading, spacing: 24) {
                    Text(spot.name)
                        .font(TPDesign.cinematicTitle(48))
                        .foregroundStyle(.white)
                        .matchedGeometryEffect(id: "title_\(spot.id)", in: namespace)

                    Text("The Atmosphere")
                        .font(TPDesign.titleFont(24))
                        .foregroundStyle(Color.tpAccent)

                    Text(spot.type.displayName)
                        .font(TPDesign.bodyFont(20))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .padding(32)
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()
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
