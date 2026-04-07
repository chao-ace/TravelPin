import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Travel.startDate, order: .reverse) private var travels: [Travel]

    @State private var showingAddTravel = false
    @State private var searchText = ""
    @State private var refreshID = UUID()

    var body: some View {
        NavigationStack {
            ZStack {
                // Background Divine Material
                TPDesign.background.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        headerSection
                        
                        WorkflowProgressSection(travels: travels)
                            .padding(.bottom, 24)

                        if travels.isEmpty {
                            emptyActionSection
                        } else {
                            // Search Bar
                            searchBarSection
                                .padding(.horizontal, 20)
                                .padding(.bottom, 24)

                            if searchText.isEmpty {
                                // Featured Cinema-Scope Section (Only shown when not searching)
                                if let latestTravel = travels.first {
                                    featuredTripSection(latestTravel)
                                        .padding(.horizontal, 20)
                                        .padding(.bottom, 32)
                                }

                                // Recent Journal List (First 3)
                                VStack(spacing: 20) {
                                    ForEach(Array(travels.prefix(3))) { travel in
                                        NavigationLink(value: travel) {
                                            TravelCard(travel: travel)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .swipeActions(travel: travel)
                                    }
                                    
                                    if travels.count > 3 {
                                        NavigationLink(destination: TravelArchiveView(travels: travels)) {
                                            HStack {
                                                Text("查看全部旅程")
                                                    .font(TPDesign.bodyFont(14, weight: .bold))
                                                Image(systemName: "arrow.right")
                                                    .font(.system(size: 12, weight: .bold))
                                            }
                                            .foregroundStyle(TPDesign.textTertiary)
                                            .padding(.vertical, 12)
                                            .padding(.horizontal, 24)
                                            .background(
                                                RoundedRectangle(cornerRadius: TPDesign.radiusMedium)
                                                    .fill(Color.white.opacity(0.95))
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: TPDesign.radiusMedium)
                                                            .stroke(
                                                                LinearGradient(
                                                                    colors: [.white.opacity(0.8), .white.opacity(0.2)],
                                                                    startPoint: .topLeading,
                                                                    endPoint: .bottomTrailing
                                                                ),
                                                                lineWidth: 0.5
                                                            )
                                                    )
                                            )
                                        }
                                        .padding(.top, 8)
                                        .cinematicFadeIn(delay: 0.3)
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.bottom, 100)
                            } else {
                                // Search Results View
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
                AddTravelView()
                    .environment(\.modelContext, modelContext)
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
            }
        }
    }
}

extension DashboardView {
    private var searchBarSection: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(TPDesign.textTertiary)
            TextField("搜索旅程名称、日期...", text: $searchText)
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
                .fill(Color.white.opacity(0.9))
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
                    Text("未找到相关旅程")
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
                HStack(spacing: 8) {
                    Text(locKey: "dashboard.header.title")
                    Text("(\(travels.count))")
                        .font(TPDesign.bodyFont(20, weight: .thin))
                }
                .font(TPDesign.editorialSerif(36))
                .foregroundStyle(TPDesign.obsidian)
                
                Text(locKey: "dashboard.header.subtitle")
                    .font(TPDesign.bodyFont(15))
                    .foregroundStyle(TPDesign.textSecondary)
                    .trackingMedium()
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
        .padding(.bottom, 24)
    }

    private var emptyActionSection: some View {
        VStack(spacing: 30) {
            ZStack {
                Circle()
                    .fill(TPDesign.celestialGlow)
                    .frame(width: 200, height: 200)
                    .opacity(0.3)
                    .blur(radius: 40)
                    
                Image(systemName: "map.circle")
                    .font(.system(size: 60, weight: .ultraLight))
                    .foregroundStyle(TPDesign.textTertiary)
            }
            .padding(.top, 20)
            
            CinematicPrimaryButton(
                locKey: "dashboard.empty.button",
                icon: "sparkles"
            ) {
                TPHaptic.notification(.success)
                showingAddTravel = true
            }
            .padding(.horizontal, 40)
            
            Spacer(minLength: 60)
        }
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
                    Text("近期旅程")
                        .font(.system(size: 10, weight: .black))
                        .tracking(2)
                        .foregroundStyle(hasPhoto ? .white.opacity(0.7) : TPDesign.textTertiary)

                    Text(travel.name)
                        .font(TPDesign.editorialSerif(28))
                        .foregroundStyle(hasPhoto ? .white : TPDesign.obsidian)

                    HStack(spacing: 16) {
                        Label("\(travel.durationDays)d", systemImage: "calendar")
                        Label("\(travel.spots.count) spots", systemImage: "mappin")
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
                        TextField("在全部旅程中搜索...", text: $archiveSearchText)
                            .font(TPDesign.bodyFont(15))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 14).fill(TPDesign.alabaster))
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
                                Text("\(year) 年")
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
        .navigationTitle("全部旅程")
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

// MARK: - Workflow Progress Section

struct WorkflowProgressSection: View {
    let travels: [Travel]
    
    @State private var isAnimating = false
    
    // Core Workflow Setup based on PRD / Docs
    let stages = [
        (title: "旅行规划", icon: "map.fill", steps: ["旅行创建", "景点收集", "行程安排", "行李准备", "出发"]),
        (title: "旅行执行", icon: "figure.walk", steps: ["查看行程", "景点打卡", "照片记录", "状态更新", "体验备注"]),
        (title: "足迹回顾", icon: "photo.fill.on.rectangle.fill", steps: ["足迹统计", "照片整理", "回忆分享", "经验总结", "下次规划"])
    ]
    
    // Determine the current workflow stage
    var currentStage: Int {
        if travels.isEmpty { return 0 }
        if travels.contains(where: { $0.status == .traveling }) { return 1 }
        if travels.contains(where: { $0.status == .wishing || $0.status == .planning }) { return 0 }
        return 2 // All travelled
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Visual Rings
            HStack(spacing: 0) {
                ForEach(0..<3) { index in
                    let isCompleted = index < currentStage
                    let isActive = index == currentStage
                    
                    VStack(spacing: 8) {
                        ZStack {
                            if isActive {
                                Circle()
                                    .stroke(Color.tpAccent, style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
                                    .frame(width: 52, height: 52)
                                    .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                                    .animation(.linear(duration: 8).repeatForever(autoreverses: false), value: isAnimating)
                                    .onAppear { isAnimating = true }
                                
                                Circle()
                                    .fill(Color.tpAccent.opacity(0.15))
                                    .frame(width: 42, height: 42)
                                    
                                Image(systemName: stages[index].icon)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(Color.tpAccent)
                            } else if isCompleted {
                                Circle()
                                    .fill(Color.tpAccent)
                                    .frame(width: 42, height: 42)
                                    
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(.white)
                            } else {
                                Circle()
                                    .fill(TPDesign.divider)
                                    .frame(width: 42, height: 42)
                                    
                                Image(systemName: stages[index].icon)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(TPDesign.textTertiary)
                            }
                        }
                        
                        Text(stages[index].title)
                            .font(TPDesign.captionFont())
                            .foregroundStyle(isActive ? Color.tpAccent : (isCompleted ? TPDesign.obsidian : TPDesign.textTertiary))
                    }
                    .frame(maxWidth: .infinity)
                    
                    if index < 2 {
                        Rectangle()
                            .fill(index < currentStage ? Color.tpAccent : TPDesign.divider)
                            .frame(height: 2)
                            .padding(.horizontal, -15)
                            .offset(y: -12)
                            .zIndex(-1)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 10)
            
            // Sub-steps for the Active Stage
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.triangle.branch")
                        .foregroundStyle(TPDesign.warmAmber)
                    Text("\(stages[currentStage].title)指南")
                        .font(TPDesign.bodyFont(14, weight: .bold))
                        .foregroundStyle(TPDesign.obsidian)
                }
                .padding(.horizontal, 16)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        let activeSteps = stages[currentStage].steps
                        ForEach(0..<activeSteps.count, id: \.self) { stepIndex in
                            Text(activeSteps[stepIndex])
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(TPDesign.obsidian)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.8))
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(TPDesign.divider, lineWidth: 0.5))
                            
                            if stepIndex < activeSteps.count - 1 {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(TPDesign.textTertiary)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.8))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(TPDesign.divider, lineWidth: 0.5))
            )
            .padding(.horizontal, 20)
        }
    }
}
