import SwiftUI
import SwiftData

struct FootprintReviewView: View {
    @Query private var travels: [Travel]
    @Query private var spots: [Spot]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                headerSection
                
                statsGrid
                
                typeDistributionSection
                
                recentActivitySection
            }
            .padding()
        }
        .navigationTitle("footprint.title".localized)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(locKey: "footprint.header.title")
                .font(TPDesign.titleFont(28))
            Text(locKey: "footprint.header.subtitle")
                .font(TPDesign.bodyFont())
                .foregroundStyle(.secondary)
        }
    }
    
    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            StatCard(title: "footprint.stat.journeys".localized, value: "\(travels.count)", icon: "map.fill")
            StatCard(title: "footprint.stat.spots".localized, value: "\(spots.count)", icon: "mappin.and.ellipse")
            StatCard(title: "footprint.stat.photos".localized, value: "\(spots.reduce(0) { $0 + $1.photoData.count })", icon: "photo.stack")
            StatCard(title: "footprint.stat.planning".localized, value: "\(travels.filter { $0.status == .planning }.count)", icon: "pencil.and.outline")
        }
    }
    
    private var typeDistributionSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(locKey: "footprint.section.distribution")
                .font(TPDesign.titleFont(20))
            
            VStack(spacing: 12) {
                ForEach(TravelType.allCases, id: \.self) { type in
                    let count = travels.filter { $0.type == type }.count
                    if count > 0 {
                        HStack {
                            Label(type.displayName, systemImage: type.icon)
                                .font(TPDesign.bodyFont())
                            Spacer()
                            Text("\(count)")
                                .fontWeight(.bold)
                        }
                        .padding()
                        .glassCard(cornerRadius: 16)
                    }
                }
            }
        }
    }
    
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(locKey: "footprints.section.recent")
                .font(TPDesign.titleFont(20))
            
            ForEach(travels.prefix(3)) { travel in
                HStack {
                    VStack(alignment: .leading) {
                        Text(travel.name)
                            .font(TPDesign.bodyFont(18))
                        Text(travel.startDate.formatted(.dateTime.year().month()))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.tertiary)
                }
                .padding()
                .glassCard(cornerRadius: 16)
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.tpAccent)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(TPDesign.titleFont(24))
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .glassCard(cornerRadius: 20)
    }
}

#Preview {
    FootprintReviewView()
}
