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
        .navigationTitle("Footprint Review")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Your Journey Insights")
                .font(TPDesign.titleFont(28))
            Text("A summary of your travel architecture.")
                .font(TPDesign.bodyFont())
                .foregroundStyle(.secondary)
        }
    }
    
    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            StatCard(title: "Journeys", value: "\(travels.count)", icon: "map.fill")
            StatCard(title: "Spots", value: "\(spots.count)", icon: "mappin.and.ellipse")
            StatCard(title: "Photos", value: "\(spots.reduce(0) { $0 + $1.photoData.count })", icon: "photo.stack")
            StatCard(title: "Planning", value: "\(travels.filter { $0.status == .planning }.count)", icon: "pencil.and.outline")
        }
    }
    
    private var typeDistributionSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Travel Distribution")
                .font(TPDesign.titleFont(20))
            
            VStack(spacing: 12) {
                ForEach(TravelType.allCases, id: \.self) { type in
                    let count = travels.filter { $0.type == type }.count
                    if count > 0 {
                        HStack {
                            Label(type.rawValue, systemImage: type.icon)
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
            Text("Recent Milestones")
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
