import SwiftUI
import SwiftData

enum StatType: String {
    case journeys, spots, photos, planning
    
    var title: String {
        switch self {
        case .journeys: return "旅程"
        case .spots: return "去过"
        case .photos: return "相册"
        case .planning: return "策划"
        }
    }
}

struct StatDetailView: View {
    let type: StatType
    @Environment(\.modelContext) private var modelContext
    @Query private var travels: [Travel]
    @Query private var spots: [Spot]
    
    // State to handle navigation to the associated travel
    @State private var selectedTravel: Travel? = nil
    
    var body: some View {
        ZStack {
            TPDesign.background.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    headerSection
                    contentSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
            }
        }
        .navigationTitle(type.title)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(type.title)
                .font(TPDesign.editorialSerif(36))
                .foregroundStyle(TPDesign.obsidian)
            
            let countStr: String = {
                switch type {
                case .journeys: return "\(travels.count) 段回顾"
                case .spots: return "\(uniqueSpots.count) 个足迹"
                case .photos: return "\(allPhotos.count) 张记忆"
                case .planning: return "\(travels.filter { $0.status == .planning }.count) 个计划"
                }
            }()
            
            Text(countStr)
                .font(TPDesign.bodyFont(16).weight(.bold))
                .foregroundStyle(TPDesign.textSecondary)
        }
    }
    
    @ViewBuilder
    private var contentSection: some View {
        switch type {
        case .journeys:
            journeyList
        case .spots:
            spotList
        case .photos:
            photoGallery
        case .planning:
            planningList
        }
    }
    
    private var journeyList: some View {
        VStack(spacing: 20) {
            ForEach(travels) { travel in
                NavigationLink(destination: TravelDetailView(travel: travel)) {
                    TravelCard(travel: travel)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private var planningList: some View {
        VStack(spacing: 20) {
            let planningTravels = travels.filter { $0.status == .planning }
            if planningTravels.isEmpty {
                emptyState(msg: "暂无策划中的旅程")
            } else {
                ForEach(planningTravels) { travel in
                    NavigationLink(destination: TravelDetailView(travel: travel)) {
                        TravelCard(travel: travel)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private var spotList: some View {
        VStack(spacing: 16) {
            if uniqueSpots.isEmpty {
                emptyState(msg: "还没有记录过足迹")
            } else {
                ForEach(uniqueSpots) { spot in
                    if let travel = spot.travel {
                        NavigationLink(destination: TravelDetailView(travel: travel)) {
                            spotRow(spot: spot)
                        }
                        .buttonStyle(.plain)
                    } else {
                        spotRow(spot: spot)
                    }
                }
            }
        }
    }
    
    private func spotRow(spot: Spot) -> some View {
        HStack(spacing: 16) {
            ZStack {
                if let photo = spot.photos.first, let data = photo.data, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else if let snapshot = spot.mapSnapshot, let uiImage = UIImage(data: snapshot) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    TPDesign.alabaster
                }
            }
            .frame(width: 64, height: 64)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(TPDesign.divider, lineWidth: 0.5))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(spot.name)
                    .font(TPDesign.bodyFont(17).weight(.bold))
                    .foregroundStyle(TPDesign.obsidian)
                
                HStack(spacing: 4) {
                    Image(systemName: spot.type.icon)
                        .font(.system(size: 10))
                    Text(spot.type.displayName)
                        .font(TPDesign.captionFont())
                }
                .foregroundStyle(TPDesign.textTertiary)
                
                if let travelName = spot.travel?.name {
                    Text("来自: \(travelName)")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.tpAccent.opacity(0.8))
                        .padding(.top, 2)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(TPDesign.divider)
        }
        .padding(12)
        .background(TPDesign.alabaster)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadowSmall()
    }
    
    private var photoGallery: some View {
        let photos = allPhotos
        
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(0..<photos.count, id: \.self) { index in
                let item = photos[index]
                // item.data is already guaranteed to be non-optional by the filter in allPhotos
                if let uiImage = UIImage(data: item.data) {
                    NavigationLink(destination: TravelDetailView(travel: item.travel)) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .aspectRatio(1, contentMode: .fill)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.1), lineWidth: 0.5))
                    }
                }
            }
        }
    }
    
    private func emptyState(msg: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "archivebox")
                .font(.largeTitle)
                .foregroundStyle(TPDesign.divider)
            Text(msg)
                .font(TPDesign.bodyFont())
                .foregroundStyle(TPDesign.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }
    
    // Computed data
    private var uniqueSpots: [Spot] {
        var result = [Spot]()
        var seenNames = Set<String>()
        
        // Strategy: First collect all with photos, then fill in with map snapshots, then the rest
        let sorted = spots.sorted { s1, s2 in
            if !s1.photos.isEmpty && s2.photos.isEmpty { return true }
            if s1.photos.isEmpty && !s2.photos.isEmpty { return false }
            return s1.name < s2.name
        }
        
        for spot in sorted {
            if !seenNames.contains(spot.name) {
                result.append(spot)
                seenNames.insert(spot.name)
            }
        }
        return result.sorted(by: { $0.name < $1.name })
    }
    
    private var allPhotos: [(data: Data, travel: Travel)] {
        var results: [(Data, Travel)] = []
        for spot in spots {
            if let travel = spot.travel {
                for photo in spot.photos {
                    if let data = photo.data {
                        results.append((data, travel))
                    }
                }
            }
        }
        return results
    }
}
