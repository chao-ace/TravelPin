import SwiftUI
import SwiftData

struct TravelDetailView: View {
    @Bindable var travel: Travel
    @Environment(\.modelContext) private var modelContext

    @State private var showingAddItinerary = false
    @State private var showingAddSpot = false
    @State private var showingAIGeneration = false // Renamed to match existing AIGenerationView
    @State private var showingEditTravel = false

    @State private var editingSpot: Spot? = nil
    @State private var editingItinerary: Itinerary? = nil
    @State private var preselectedItineraryForSpot: Itinerary? = nil

    @ObservedObject var realtime = RealtimeManager.shared
    @Namespace private var animation
    @State private var selectedSpot: Spot? = nil
    @ObservedObject var intelligence = IntelligenceService.shared

    var body: some View {
        ZStack {
            // Background Material
            TPDesign.background.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    // Immersive Photo Wall / Brand Header (Full-bleed 16:9)
                    headerSection
                        .onAppear {
                            intelligence.performVibeCheck(for: travel)
                        }

                    // Intelligence Advice Overlay (Subtle floating valet)
                    IntelligenceBanner(travel: travel)
                        .padding(.top, -30) // Overlap the header for a layered look
                        .zIndex(10)

                    // Body Sections
                    VStack(alignment: .leading, spacing: 48) {
                        itinerarySection
                        spotArchiveSection
                        luggageMiniSection
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 120)
                    .background(TPDesign.background) // Re-assert the background here
                }
            }
            .blur(radius: selectedSpot != nil ? 10 : 0)

            // Full Screen Immersive Expansion Overlay
            if let spot = selectedSpot {
                ImmersiveSpotDetailView(spot: spot, namespace: animation, onEdit: {
                    editingSpot = spot
                }) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        selectedSpot = nil
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                appMenu
            }
        }
        .sheet(isPresented: $showingAddItinerary) {
            AddItineraryView(travel: travel, initialDay: travel.itineraries.count + 1)
        }
        .sheet(isPresented: $showingAddSpot) {
            AddSpotView(travel: travel, preselectedItinerary: preselectedItineraryForSpot)
        }
        .sheet(isPresented: $showingAIGeneration) {
            AIGenerationView(travel: travel)
        }
        .sheet(isPresented: $showingEditTravel) {
            EditTravelView(travel: travel)
        }
        .sheet(item: $editingSpot) { spot in
            EditSpotView(spot: spot, travel: travel)
        }
        .sheet(item: $editingItinerary) { itinerary in
            EditItineraryView(itinerary: itinerary)
        }
    }

    private var headerSection: some View {
        let heroHeight = UIScreen.main.bounds.width * (9.0 / 16.0)
        
        return ZStack(alignment: .bottomLeading) {
            // Dynamic Background: Rotating Photo Wall or Brand Blue placeholder
            let photos = travel.spots.flatMap { $0.photos }.filter { $0.data != nil }
            
            Group {
                if !photos.isEmpty {
                    TabView {
                        ForEach(photos, id: \.persistentModelID) { photo in
                            if let data = photo.data, let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: UIScreen.main.bounds.width, height: heroHeight)
                                    .clipped()
                            }
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                } else {
                    // Celestial Silk Gradient: Ultra-smooth White to Celestial Blue
                    ZStack {
                        LinearGradient(
                            stops: [
                                .init(color: .white, location: 0),
                                .init(color: TPDesign.celestialBlue.opacity(0.3), location: 0.5),
                                .init(color: TPDesign.celestialBlue, location: 1.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        
                        Image(systemName: travel.type.icon)
                            .font(.system(size: 80, weight: .ultraLight))
                            .foregroundStyle(TPDesign.celestialBlue.opacity(0.15))
                            .offset(y: -20)
                    }
                }
            }
            .frame(width: UIScreen.main.bounds.width, height: heroHeight)

            // Title Overlay (Flush to Bottom)
            VStack(alignment: .leading, spacing: 8) {
                Text(travel.name)
                    .font(TPDesign.editorialSerif(40))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                
                HStack(spacing: 12) {
                    Label(travel.startDate.formatted(.dateTime.month().day()) + " - " + travel.endDate.formatted(.dateTime.day().month().year()), systemImage: "calendar")
                    Label("\(travel.itineraries.count) Days", systemImage: "clock")
                }
                .font(TPDesign.captionFont())
                .foregroundStyle(.white.opacity(0.9))
                .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
            }
            .padding(32)
            .padding(.bottom, 20) // Leave space for Intelligence overlap
            .background(
                LinearGradient(colors: [.black.opacity(0.5), .clear], startPoint: .bottom, endPoint: .top)
            )
        }
    }

    private var appMenu: some View {
        Menu {
            Button(action: { showingEditTravel = true }) {
                Label("编辑旅程", systemImage: "pencil")
            }
            Divider()
            NavigationLink(destination: TravelMapView(travel: travel)) {
                Label("查看地图", systemImage: "map")
            }
            NavigationLink(destination: LuggageView(travel: travel)) {
                Label("行李清单", systemImage: "bag")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.title2)
                .foregroundStyle(TPDesign.obsidian)
        }
    }

    private var itinerarySection: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(alignment: .bottom) {
                Text(locKey: "detail.itinerary.title")
                    .font(TPDesign.editorialSerif(28))
                    .foregroundStyle(TPDesign.obsidian)
                
                Spacer()
                
                Button {
                    TPHaptic.notification(.success)
                    showingAIGeneration.toggle()
                } label: {
                    Image(systemName: "wand.and.stars.inverse")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.tpAccent)
                        .padding(8)
                        .background(Circle().fill(Color.tpAccent.opacity(0.1)))
                }
                .offset(y: 4)
            }
            .padding(.horizontal, 24)

            if travel.itineraries.isEmpty {
                VStack(alignment: .leading, spacing: 20) {
                    Text(locKey: "detail.itinerary.empty")
                        .font(TPDesign.bodyFont())
                        .foregroundStyle(TPDesign.textTertiary)
                    
                    Button {
                        showingAddItinerary.toggle()
                    } label: {
                        Label("添加第一天", systemImage: "plus.circle.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Color.tpAccent)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(Color.tpAccent.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 24)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    let sortedItineraries = travel.itineraries.sorted(by: { $0.day < $1.day })
                    ForEach(Array(sortedItineraries.enumerated()), id: \.element.persistentModelID) { index, itinerary in
                        ItineraryRow(
                            travel: travel,
                            itinerary: itinerary,
                            isLast: index == sortedItineraries.count - 1,
                            onEdit: { editingItinerary = itinerary },
                            onAddSpot: {
                                preselectedItineraryForSpot = itinerary
                                showingAddSpot.toggle()
                            },
                            onEditSpot: { spot in
                                editingSpot = spot
                            },
                            onToggleComplete: {
                                TPHaptic.notification(itinerary.isCompleted ? .warning : .success)
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    itinerary.isCompleted.toggle()
                                    try? modelContext.save()
                                }
                            }
                        )
                    }
                    
                    HStack(alignment: .center, spacing: 16) {
                        VStack(spacing: 0) {
                            Rectangle()
                                .fill(Color.tpAccent.opacity(0.6))
                                .frame(width: 2, height: 16)

                            Button {
                                TPHaptic.selection()
                                showingAddItinerary.toggle()
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 28, height: 28)
                                    Circle()
                                        .strokeBorder(Color.tpAccent.opacity(0.5), style: StrokeStyle(lineWidth: 1.5, dash: [4]))
                                        .frame(width: 28, height: 28)
                                    Image(systemName: "plus")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(Color.tpAccent)
                                }
                            }
                            .buttonStyle(.plain)
                            
                            Rectangle()
                                .fill(LinearGradient(colors: [Color.tpAccent.opacity(0.3), .clear], startPoint: .top, endPoint: .bottom))
                                .frame(width: 2, height: 24)
                        }
                        .frame(width: 28)
                        
                        Button {
                            TPHaptic.mechanicalPress()
                            showingAddItinerary.toggle()
                        } label: {
                            Text("添加第 \(travel.itineraries.count + 1) 天")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(Color.tpAccent)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(Color.tpAccent.opacity(0.08))
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(Color.tpAccent.opacity(0.2), lineWidth: 1))
                        }
                        .padding(.bottom, 8)
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
        .cinematicFadeIn(delay: 0.3)
    }

    private var spotArchiveSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(locKey: "detail.archive.title")
                .font(TPDesign.editorialSerif(28))
                .foregroundStyle(TPDesign.obsidian)
                .padding(.horizontal, 24)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    // Unique spots based on name to prevent duplication
                    let uniqueSpots = travel.spots.reduce(into: [Spot]()) { result, spot in
                        if !result.contains(where: { $0.name == spot.name }) {
                            result.append(spot)
                        } else if let existingIndex = result.firstIndex(where: { $0.name == spot.name }) {
                            // Replacement logic: Prioritize spots that actually have photos
                            if result[existingIndex].photos.isEmpty && !spot.photos.isEmpty {
                                result[existingIndex] = spot
                            }
                        }
                    }.filter { !$0.photos.isEmpty || $0.mapSnapshot != nil }
                    
                    if uniqueSpots.isEmpty {
                        Text("暂无高光时刻")
                            .font(TPDesign.bodyFont(14))
                            .foregroundStyle(TPDesign.textTertiary)
                            .padding(.vertical, 20)
                    } else {
                        ForEach(uniqueSpots) { spot in
                            SpotHighlightCard(spot: spot, namespace: animation) {
                                TPHaptic.impact(.medium)
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                    selectedSpot = spot
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
        }
        .cinematicFadeIn(delay: 0.4)
    }

    private var luggageMiniSection: some View {
        NavigationLink(destination: LuggageView(travel: travel)) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(locKey: "detail.packing.title")
                        .font(TPDesign.editorialSerif(22))
                    Text("\(travel.luggageItems.filter { $0.isChecked }.count)/\(travel.luggageItems.count) 已准备")
                        .font(TPDesign.bodyFont(14))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.tertiary)
            }
            .padding(20)
            .background(TPDesign.alabaster)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(TPDesign.obsidian.opacity(0.05), lineWidth: 0.5))
            .padding(.horizontal, 24)
        }
        .buttonStyle(.plain)
        .cinematicFadeIn(delay: 0.5)
    }
}

// MARK: - Subviews

struct ItineraryRow: View {
    let travel: Travel
    let itinerary: Itinerary
    var isLast: Bool = false
    var onEdit: () -> Void
    var onAddSpot: () -> Void
    var onEditSpot: (Spot) -> Void
    var onToggleComplete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(spacing: 0) {
                Button(action: onToggleComplete) {
                    ZStack {
                        Circle()
                            .fill(itinerary.isCompleted ? Color.tpAccent : Color.white)
                            .frame(width: 28, height: 28)
                            .shadow(color: (itinerary.isCompleted ? Color.tpAccent : Color.tpAccent).opacity(0.15), radius: 6, x: 0, y: 3)
                        Circle()
                            .stroke(itinerary.isCompleted ? Color.tpAccent : Color.tpAccent, lineWidth: 2)
                            .frame(width: 28, height: 28)
                        
                        if itinerary.isCompleted {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .black))
                                .foregroundStyle(Color.white)
                        } else {
                            Text("D\(itinerary.day)")
                                .font(.system(size: 10, weight: .black, design: .rounded))
                                .foregroundStyle(Color.tpAccent)
                        }
                    }
                }
                .buttonStyle(.plain)
                
                Rectangle()
                    .fill(LinearGradient(colors: [Color.tpAccent.opacity(0.6), isLast ? .clear : Color.tpAccent.opacity(0.6)], startPoint: .top, endPoint: .bottom))
                    .frame(width: 2)
                    .padding(.vertical, 4)
            }
            .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 16) {
                Button(action: onEdit) {
                    HStack {
                        Text("\(itinerary.origin) → \(itinerary.destination)")
                            .font(TPDesign.editorialSerif(20))
                            .foregroundStyle(TPDesign.obsidian)
                        Image(systemName: "pencil")
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)

                let dailySpots = travel.spots.filter { $0.itinerary?.persistentModelID == itinerary.persistentModelID }.sorted { $0.sequence < $1.sequence }
                if !dailySpots.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(dailySpots) { spot in
                            Button {
                                onEditSpot(spot)
                            } label: {
                                HStack(spacing: 10) {
                                    Circle()
                                        .fill(Color.tpAccent.opacity(0.2))
                                        .frame(width: 6, height: 6)
                                    Label(spot.name, systemImage: spot.type.icon)
                                        .font(TPDesign.bodyFont(15))
                                        .foregroundStyle(TPDesign.textSecondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.leading, 2)
                }

                HStack(spacing: 12) {
                    Button(action: onAddSpot) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle.fill")
                            Text("添加地点")
                        }
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.tpAccent)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(Color.tpAccent.opacity(0.08))
                        .clipShape(Capsule())
                    }
                }
                .padding(.top, 4)
            }
            .padding(.bottom, 40)
            .opacity(itinerary.isCompleted ? 0.6 : 1.0)
        }
        .padding(.horizontal, 24)
    }
}

struct SpotHighlightCard: View {
    let spot: Spot
    var namespace: Namespace.ID
    let onTap: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            ZStack(alignment: .bottomLeading) {
                Group {
                    if let firstPhoto = spot.photos.first, let data = firstPhoto.data, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage).resizable().scaledToFill()
                    } else if let snapshotData = spot.mapSnapshot, let uiImage = UIImage(data: snapshotData) {
                        Image(uiImage: uiImage).resizable().scaledToFill()
                    } else {
                        Rectangle().fill(TPDesign.obsidian.opacity(0.1))
                            .overlay(Image(systemName: "mappin.and.ellipse").foregroundStyle(.white.opacity(0.2)))
                    }
                }
                .matchedGeometryEffect(id: "image_\(spot.persistentModelID)", in: namespace)
                .frame(width: 280, height: 280 * (9.0 / 16.0))
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(0.2), lineWidth: 0.3))

                LinearGradient(colors: [.black.opacity(0.7), .clear], startPoint: .bottom, endPoint: .top)
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                VStack(alignment: .leading, spacing: 4) {
                    Text(spot.name)
                        .font(TPDesign.editorialSerif(22))
                        .foregroundStyle(.white)
                    Text(spot.type.displayName.uppercased())
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(.white.opacity(0.6))
                        .tracking(2)
                }
                .padding(20)
                .matchedGeometryEffect(id: "title_\(spot.persistentModelID)", in: namespace)
            }
        }
        .buttonStyle(.plain)
    }
}

struct ImmersiveSpotDetailView: View {
    let spot: Spot
    var namespace: Namespace.ID
    var onEdit: () -> Void
    let onClose: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Rectangle()
                .fill(.black.opacity(0.45))
                .background(.ultraThinMaterial)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        if spot.photos.isEmpty {
                            if let snapshot = spot.mapSnapshot, let uiImage = UIImage(data: snapshot) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: UIScreen.main.bounds.width)
                                    .clipShape(Rectangle())
                                    .overlay(
                                        VStack {
                                            Spacer()
                                            HStack {
                                                Label("地图概览", systemImage: "map.fill")
                                                    .font(.system(size: 10, weight: .bold))
                                                    .foregroundStyle(.white)
                                                    .padding(.horizontal, 10).padding(.vertical, 5)
                                                    .background(.black.opacity(0.4)).clipShape(Capsule())
                                                Spacer()
                                            }.padding(20)
                                        }
                                    )
                            } else {
                                ZStack {
                                    TPDesign.obsidian.frame(width: UIScreen.main.bounds.width)
                                    Image(systemName: "photo").font(.system(size: 40)).foregroundStyle(.white.opacity(0.2))
                                }
                            }
                        } else {
                            ForEach(spot.photos) { photo in
                                if let data = photo.data, let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: UIScreen.main.bounds.width)
                                        .clipShape(Rectangle())
                                }
                            }
                        }
                    }
                }
                .frame(height: UIScreen.main.bounds.height * 0.55)
                .matchedGeometryEffect(id: "image_\(spot.persistentModelID)", in: namespace)
                .scrollTargetBehavior(.paging)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(spot.type.displayName.uppercased())
                                    .font(.system(size: 10, weight: .black)).tracking(3).foregroundStyle(Color.tpAccent)
                                Text(spot.name)
                                    .font(TPDesign.editorialSerif(44)).foregroundStyle(.white).lineLimit(2)
                                    .matchedGeometryEffect(id: "title_\(spot.persistentModelID)", in: namespace)
                            }
                            Spacer()
                            Button(action: onEdit) {
                                Image(systemName: "pencil.circle.fill").font(.system(size: 32)).foregroundStyle(.white.opacity(0.3))
                            }
                        }

                        if !spot.notes.isEmpty {
                            VStack(alignment: .leading, spacing: 14) {
                                HStack {
                                    Rectangle().fill(Color.tpAccent).frame(width: 4, height: 16)
                                    Text("氛围与印象").font(TPDesign.overline()).foregroundStyle(.secondary)
                                }
                                Text(spot.notes).font(TPDesign.bodyFont(18)).foregroundStyle(.white.opacity(0.9)).lineSpacing(10)
                            }
                            .padding(24).background(Color.white.opacity(0.05)).clipShape(RoundedRectangle(cornerRadius: 24))
                            .overlay(RoundedRectangle(cornerRadius: 24).stroke(.white.opacity(0.1), lineWidth: 0.5))
                        }
                        
                        if let snapshot = spot.mapSnapshot, let uiImage = UIImage(data: snapshot) {
                            VStack(alignment: .leading, spacing: 14) {
                                Text("地点指引").font(TPDesign.overline()).foregroundStyle(.secondary)
                                Image(uiImage: uiImage).resizable().scaledToFill().frame(height: 120)
                                    .clipShape(RoundedRectangle(cornerRadius: 18))
                                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(0.2), lineWidth: 0.5))
                            }
                        }
                    }
                    .padding(32)
                }
            }

            Button(action: onClose) {
                Image(systemName: "xmark").font(.system(size: 16, weight: .black)).foregroundStyle(.white)
                    .frame(width: 44, height: 44).background(Circle().fill(.white.opacity(0.15)))
                    .background(Circle().stroke(.white.opacity(0.2), lineWidth: 1))
            }
            .padding(24)
        }
        .transition(.asymmetric(insertion: .identity, removal: .opacity))
    }
}
