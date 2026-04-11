import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Travel.startDate, order: .reverse) private var travels: [Travel]

    @State private var showingAddTravel = false
    @State private var searchText = ""
    @State private var refreshID = UUID()
    @State private var emptyPulsing = false
    @State private var showingDNA = false
    @State private var showingMemoryCapsule = false
    @State private var memoryTravel: Travel?

    var body: some View {
        NavigationStack {
            ZStack {
                TPDesign.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        headerSection

                        // Compact progress bar (replaces bulky WorkflowProgressSection)
                        CompactWorkflowBar(travels: travels)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 20)

                        if travels.isEmpty {
                            emptyActionSection
                        } else {
                            searchBarSection
                                .padding(.horizontal, 20)
                                .padding(.bottom, 20)

                            if searchText.isEmpty {
                                // Memory Capsule Banner (if milestone)
                                memoryCapsuleBanner

                                // Travel DNA Card
                                if !travels.filter({ $0.status == .travelled || $0.isCompleted }).isEmpty {
                                    dnaCard
                                }

                                statusGroupedSections
                            } else {
                                searchResultsSection
                            }
                        }
                    }
                }
                .id(refreshID)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingAddTravel) {
                AddTravelWizardView()
                    .environment(\.modelContext, modelContext)
            }
            .sheet(isPresented: $showingDNA) {
                TravelDNAView(dna: TravelDNAService.shared.generateDNA(from: travels))
            }
            .sheet(item: $memoryTravel) { travel in
                MemoryCapsuleLoader(travel: travel)
            }
            .navigationDestination(for: Travel.self) { travel in
                TravelDetailView(travel: travel)
            }
            .onChange(of: travels.count) { _, _ in
                refreshID = UUID()
                AppState.shared.updateWidgetData(travels: travels)
            }
            .onAppear {
                refreshID = UUID()
                AppState.shared.updateWidgetData(travels: travels)
                TravelLogicService.autoTransitionStatus(travels: travels, context: modelContext)
                // Schedule memory notifications for completed trips
                Task {
                    await MemoryService.shared.scheduleMemoryNotifications(travels: travels)
                }
            }
        }
    }

    // MARK: - Status-Grouped Travel Sections

    private var statusGroupedSections: some View {
        VStack(alignment: .leading, spacing: 32) {
            // UPCOMING
            let upcoming = travels.filter { ($0.status == .planning || $0.status == .wishing) && $0.isUpcoming }
            if !upcoming.isEmpty {
                travelGroupSection(
                    title: "dashboard.section.upcoming".localized,
                    icon: "calendar.badge.clock",
                    color: TPDesign.celestialBlue,
                    travels: Array(upcoming.prefix(2))
                )
            }

            // ACTIVE
            let active = travels.filter { $0.status == .traveling || $0.isActive }
            if !active.isEmpty {
                travelGroupSection(
                    title: "dashboard.section.active".localized,
                    icon: "airplane.departure",
                    color: .green,
                    travels: Array(active.prefix(2))
                )
            }

            // RECENTLY COMPLETED — Featured trip goes here
            let completed = travels.filter { $0.status == .travelled }
            if !completed.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    sectionHeader(
                        title: "dashboard.section.completed".localized,
                        icon: "checkmark.seal.fill",
                        color: TPDesign.textSecondary
                    )

                    // Featured card for the latest completed trip
                    if let latestCompleted = completed.first {
                        featuredTripSection(latestCompleted)
                    }

                    ForEach(Array(completed.dropFirst().prefix(2))) { travel in
                        NavigationLink(value: travel) {
                            TravelCard(travel: travel)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .swipeActions(travel: travel)
                    }
                }
                .padding(.horizontal, 20)
            }

            // View All
            if travels.count > 5 {
                NavigationLink(destination: TravelArchiveView(travels: travels)) {
                    HStack {
                        Text(locKey: "dashboard.action.view_all")
                            .font(TPDesign.bodyFont(14, weight: .bold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundStyle(TPDesign.textTertiary)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(
                        RoundedRectangle(cornerRadius: TPDesign.radiusMedium)
                            .fill(TPDesign.secondaryBackground.opacity(0.95))
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: TPDesign.radiusMedium))
                    )
                }
                .padding(.horizontal, 20)
            }

            Spacer(minLength: 100)
        }
    }

    private func travelGroupSection(title: String, icon: String, color: Color, travels: [Travel]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: title, icon: icon, color: color)

            ForEach(travels) { travel in
                NavigationLink(value: travel) {
                    TravelCard(travel: travel)
                }
                .buttonStyle(PlainButtonStyle())
                .swipeActions(travel: travel)
            }
        }
        .padding(.horizontal, 20)
    }

    private func sectionHeader(title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(color)
            Text(title)
                .font(TPDesign.overline())
                .foregroundStyle(TPDesign.textTertiary)
                .tracking(2)
        }
        .padding(.horizontal, 4)
    }
}

extension DashboardView {
    private var searchBarSection: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(TPDesign.textTertiary)
            TextField("dashboard.search.placeholder".localized, text: $searchText)
                .font(TPDesign.bodyFont(15))
            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(TPDesign.textTertiary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(TPDesign.secondaryBackground.opacity(0.8))
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(TPDesign.divider, lineWidth: 0.5))
        )
    }

    private var searchResultsSection: some View {
        let filtered = travels.filter { travel in
            searchText.isEmpty || 
            travel.name.localizedStandardContains(searchText) ||
            travel.startDate.formatted().contains(searchText)
        }

        return VStack(alignment: .leading, spacing: 20) {
            if filtered.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.largeTitle)
                        .foregroundStyle(TPDesign.textTertiary)
                    Text(locKey: "dashboard.search.empty")
                        .font(TPDesign.bodyFont(16))
                        .foregroundStyle(TPDesign.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 60)
            } else {
                ForEach(filtered) { travel in
                    NavigationLink(value: travel) {
                        TravelCard(travel: travel)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 100)
    }

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(greetingText)
                    .font(TPDesign.bodyFont(15, weight: .medium))
                    .foregroundStyle(TPDesign.textSecondary)
                    .trackingMedium()

                HStack(spacing: 8) {
                    Text(locKey: "dashboard.header.title")
                    Text("(\(travels.count))")
                        .font(TPDesign.bodyFont(20, weight: .thin))
                }
                .font(TPDesign.editorialSerif(36))
                .foregroundStyle(TPDesign.obsidian)

                // Quick stats pill
                if !travels.isEmpty {
                    HStack(spacing: 6) {
                        Text("\(travels.count)\("dashboard.recent.days_suffix".localized.dropLast())")
                            .font(TPDesign.captionFont())
                        Text("·")
                            .foregroundStyle(TPDesign.textTertiary)
                        Text("\(travels.reduce(0) { $0 + $1.spots.count })\("dashboard.recent.spots_suffix".localized)")
                            .font(TPDesign.captionFont())
                    }
                    .foregroundStyle(TPDesign.textSecondary)
                }
            }

            Spacer()

            Button {
                TPHaptic.mechanicalPress()
                showingAddTravel = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(TPDesign.brandGradient)
                    .clipShape(Circle())
                    .shadowSmall()
            }
            .offset(y: 4)
        }
        .padding(.horizontal, 24)
        .padding(.top, 40)
        .padding(.bottom, 20)
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 {
            return "dashboard.greeting.morning".localized
        } else if hour < 18 {
            return "dashboard.greeting.afternoon".localized
        } else {
            return "dashboard.greeting.evening".localized
        }
    }

    // MARK: - Memory Capsule Banner

    @ViewBuilder
    private var memoryCapsuleBanner: some View {
        let milestones = MemoryService.shared.checkMemoryMilestones(travels: travels)
        if let travel = milestones.first {
            let daysAgo = Calendar.current.dateComponents([.day], from: travel.endDate, to: Date()).day ?? 0
            Button {
                memoryTravel = travel
            } label: {
                MemoryCapsuleBanner(travel: travel, daysAgo: daysAgo)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
    }

    // MARK: - DNA Card

    private var dnaCard: some View {
        Button {
            showingDNA = true
        } label: {
            let dna = TravelDNAService.shared.generateDNA(from: travels)
            TravelDNACard(dna: dna)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    private var emptyActionSection: some View {
        VStack(spacing: 28) {
            // Hero illustration
            ZStack {
                Circle()
                    .fill(TPDesign.celestialGlow)
                    .frame(width: 160, height: 160)
                    .opacity(0.3)
                    .blur(radius: 40)
                    .scaleEffect(emptyPulsing ? 1.08 : 0.95)

                Image(systemName: "map.circle")
                    .font(.system(size: 56, weight: .ultraLight))
                    .foregroundStyle(TPDesign.textTertiary)
                    .scaleEffect(emptyPulsing ? 1.05 : 0.95)
            }
            .padding(.top, 20)
            .onAppear {
                withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                    emptyPulsing = true
                }
            }

            Text(locKey: "dashboard.empty.subtitle")
                .font(TPDesign.bodyFont(14))
                .foregroundStyle(TPDesign.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            // Quick start guide cards
            VStack(spacing: 10) {
                emptyGuideCard(
                    icon: "sparkles",
                    color: Color.tpAccent,
                    title: "dashboard.guide.create.title".localized,
                    subtitle: "dashboard.guide.create.desc".localized
                ) {
                    showingAddTravel = true
                }

                NavigationLink(destination: FootprintReviewView()) {
                    emptyGuideCardContent(
                        icon: "chart.bar.xaxis",
                        color: TPDesign.warmAmber,
                        title: "dashboard.guide.footprint.title".localized,
                        subtitle: "dashboard.guide.footprint.desc".localized
                    )
                }
                .buttonStyle(.plain)

                NavigationLink(destination: InspirationPlazaView()) {
                    emptyGuideCardContent(
                        icon: "sparkles.rectangle.stack",
                        color: TPDesign.celestialBlue,
                        title: "dashboard.guide.inspiration.title".localized,
                        subtitle: "dashboard.guide.inspiration.desc".localized
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)

            Spacer(minLength: 40)
        }
        .cinematicFadeIn(delay: 0.1)
    }

    private func emptyGuideCard(
        icon: String,
        color: Color,
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            emptyGuideCardContent(icon: icon, color: color, title: title, subtitle: subtitle)
        }
        .buttonStyle(.plain)
    }

    private func emptyGuideCardContent(icon: String, color: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(TPDesign.bodyFont(14, weight: .bold))
                    .foregroundStyle(TPDesign.textPrimary)
                Text(subtitle)
                    .font(TPDesign.bodyFont(12, weight: .regular))
                    .foregroundStyle(TPDesign.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(TPDesign.textTertiary)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: TPDesign.radiusLarge)
                .fill(TPDesign.surface1)
                .overlay(
                    RoundedRectangle(cornerRadius: TPDesign.radiusLarge)
                        .stroke(color.opacity(0.1), lineWidth: 1)
                )
        )
        .shadowSmall()
    }

    private func featuredTripSection(_ travel: Travel) -> some View {
        let hasPhoto = travel.spots.contains { !$0.photos.isEmpty }
        
        return NavigationLink(destination: TripPosterView(travel: travel)) {
            ZStack(alignment: .bottomLeading) {
                Group {
                    if let firstSpotWithPhoto = travel.spots.first(where: { !$0.photos.contains { $0.data != nil } }),
                       let photo = firstSpotWithPhoto.photos.first(where: { $0.data != nil }),
                       let data = photo.data,
                       let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                    } else {
                        TPDesign.brandGradient.opacity(0.05)
                    }
                }
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .overlay(
                    Group {
                        if hasPhoto {
                            LinearGradient(colors: [.black.opacity(0.5), .clear], startPoint: .bottom, endPoint: .center)
                        } else {
                            TPDesign.background.opacity(0.8)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                )

                VStack(alignment: .leading, spacing: 8) {
                    Text(locKey: "dashboard.recent.title")
                        .font(.system(size: 10, weight: .black))
                        .tracking(2)
                        .foregroundStyle(hasPhoto ? .white.opacity(0.7) : TPDesign.textTertiary)

                    Text(travel.name)
                        .font(TPDesign.editorialSerif(28))
                        .foregroundStyle(hasPhoto ? .white : TPDesign.obsidian)

                    HStack(spacing: 16) {
                        Label("\(travel.durationDays)\("dashboard.recent.days_suffix".localized)", systemImage: "calendar")
                        Label("\(travel.spots.count)\("dashboard.recent.spots_suffix".localized)", systemImage: "mappin")
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(hasPhoto ? .white.opacity(0.8) : TPDesign.textSecondary)
                }
                .padding(24)
            }
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(.white.opacity(0.2), lineWidth: 0.3))
            .shadowFloating()
        }
    }
}

struct TravelArchiveView: View {
    let travels: [Travel]
    @State private var archiveSearchText = ""
    
    var body: some View {
        ZStack {
            TPDesign.background.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Archive Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(TPDesign.textTertiary)
                        TextField("dashboard.archive.search.placeholder".localized, text: $archiveSearchText)
                            .font(TPDesign.bodyFont(15))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 14).fill(TPDesign.surface1.opacity(0.8)).background(.ultraThinMaterial).clipShape(RoundedRectangle(cornerRadius: 14)))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(TPDesign.divider, lineWidth: 0.5))
                    .padding(.horizontal, 20)

                    // Grouped Archive List
                    let filtered = travels.filter {
                        archiveSearchText.isEmpty || $0.name.localizedStandardContains(archiveSearchText)
                    }
                    
                    let grouped = Dictionary(grouping: filtered) { travel in
                        Calendar.current.component(.year, from: travel.startDate)
                    }.sorted { $0.key > $1.key }

                    ForEach(grouped, id: \.key) { year, yearTravels in
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                        Text("\(String(year))\("dashboard.archive.year_suffix".localized)")
                            .font(TPDesign.editorialSerif(22))
                            .foregroundStyle(TPDesign.obsidian)
                                Rectangle()
                                    .fill(TPDesign.divider)
                                    .frame(height: 1)
                            }
                            .padding(.horizontal, 20)

                            VStack(spacing: 16) {
                                ForEach(yearTravels) { travel in
                                    NavigationLink(destination: TravelDetailView(travel: travel)) {
                                        TravelCard(travel: travel)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .swipeActions(travel: travel)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.top, 8)
                    }
                }
                .padding(.vertical, 24)
            }
        }
        .navigationTitle("dashboard.archive.title".localized)
        .navigationBarTitleDisplayMode(.large)
    }
}

extension View {
    func swipeActions(travel: Travel) -> some View {
        self.modifier(SwipeActionModifier(travel: travel))
    }
}

struct SwipeActionModifier: ViewModifier {
    let travel: Travel
    @Environment(\.modelContext) private var modelContext
    @State private var offset: CGFloat = 0

    func body(content: Content) -> some View {
        ZStack(alignment: .trailing) {
            Rectangle()
                .fill(Color.red)
                .clipShape(UnevenRoundedRectangle(bottomTrailingRadius: 18, topTrailingRadius: 18))
                .frame(width: max(0, -offset))
                
            Image(systemName: "trash")
                .foregroundStyle(.white)
                .font(.system(size: 20, weight: .semibold))
                .padding(.trailing, 24)
                .opacity(-offset > 40 ? 1 : 0)
                .onTapGesture {
                    withAnimation {
                        modelContext.delete(travel)
                        try? modelContext.save()
                    }
                }

            content
                .offset(x: offset)
                .highPriorityGesture(
                    DragGesture(minimumDistance: 20)
                        .onChanged { gesture in
                            if offset == 0 && gesture.translation.width < 0 {
                                offset = max(gesture.translation.width, -80)
                            } else if offset < 0 {
                                offset = min(-80 + gesture.translation.width, 0)
                            }
                        }
                        .onEnded { gesture in
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                if gesture.translation.width < -40 {
                                    offset = -80
                                } else if gesture.translation.width > 30 {
                                    offset = 0
                                } else {
                                    offset = offset < -40 ? -80 : 0
                                }
                            }
                        }
                )
        }
    }
}

struct OnboardingTaskRow: View {
    let title: String
    let isDone: Bool

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(isDone ? Color.tpAccent : .secondary)

            Text(title)
                .font(TPDesign.bodyFont(17))
                .foregroundStyle(isDone ? .primary : TPDesign.textTertiary)
                .strikethrough(isDone)

            Spacer()
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Compact Workflow Bar (Three Stages)

private struct CompactWorkflowBar: View {
    let travels: [Travel]

    @State private var spinning = false

    private var currentStage: Int {
        if travels.isEmpty { return 0 }
        if travels.contains(where: { $0.status == .traveling }) { return 1 }
        if travels.contains(where: { $0.status == .wishing || $0.status == .planning }) { return 0 }
        return 2
    }

    private let stages = [
        (title: "dashboard.workflow.stage1".localized, icon: "map.fill"),
        (title: "dashboard.workflow.stage2".localized, icon: "figure.walk"),
        (title: "dashboard.workflow.stage3".localized, icon: "photo.fill.on.rectangle.fill")
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<3, id: \.self) { index in
                stageNode(index: index)

                if index < 2 {
                    connectorLine(isComplete: (index + 1) <= currentStage)
                }
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: TPDesign.radiusLarge)
                .fill(TPDesign.surface1.opacity(0.7))
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: TPDesign.radiusLarge))
        )
        .overlay(
            RoundedRectangle(cornerRadius: TPDesign.radiusLarge)
                .stroke(TPDesign.divider, lineWidth: 0.5)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: false)) {
                spinning = true
            }
        }
    }

    // MARK: - Stage Node

    @ViewBuilder
    private func stageNode(index: Int) -> some View {
        VStack(spacing: 6) {
            ZStack {
                if index == currentStage {
                    Circle()
                        .stroke(Color.tpAccent.opacity(0.2), lineWidth: 3)
                        .frame(width: 40, height: 40)
                        .scaleEffect(spinning ? 1.3 : 1.0)
                        .opacity(spinning ? 0 : 0.6)
                }

                Circle()
                    .fill(
                        index < currentStage
                        ? Color.tpAccent
                        : index == currentStage
                        ? Color.tpAccent.opacity(0.12)
                        : TPDesign.divider.opacity(0.5)
                    )
                    .frame(width: 32, height: 32)

                Image(systemName: index < currentStage ? "checkmark" : stages[index].icon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(
                        index < currentStage
                        ? .white
                        : index == currentStage
                        ? Color.tpAccent
                        : TPDesign.textTertiary
                    )
                    .rotationEffect(index == currentStage ? .degrees(spinning ? 360 : 0) : .zero)
            }

            Text(stages[index].title)
                .font(.system(size: 10, weight: index == currentStage ? .bold : .medium))
                .foregroundStyle(index == currentStage ? Color.tpAccent : TPDesign.textTertiary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Connector Line

    @ViewBuilder
    private func connectorLine(isComplete: Bool) -> some View {
        Rectangle()
            .fill(isComplete ? Color.tpAccent.opacity(0.4) : TPDesign.divider)
            .frame(height: 2)
            .padding(.top, 15) // align with circle center
    }
}

// MARK: - Memory Capsule Loader

private struct MemoryCapsuleLoader: View {
    let travel: Travel
    @State private var memory: MemoryItem?

    var body: some View {
        Group {
            if let memory {
                MemoryCapsuleView(memory: memory)
            } else {
                ZStack {
                    TPDesign.cinematicGradient.ignoresSafeArea()
                    ProgressView()
                        .tint(.white)
                }
            }
        }
        .task {
            memory = await MemoryService.shared.generateMemory(for: travel)
        }
    }
}
