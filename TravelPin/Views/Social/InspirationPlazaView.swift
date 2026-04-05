import SwiftUI
import SwiftData

struct InspirationPlazaView: View {
    @State private var publicTrips: [Travel] = [] // Loaded from Supabase
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerSection
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                        ForEach(publicTrips) { trip in
                            TripResonanceCard(travel: trip) {
                                // Action: Clone/Remix
                                remixTrip(trip)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Inspiration Plaza")
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Find Your Next Horizon")
                .font(TPDesign.titleFont(28))
            Text("Discover and remix plans from global explorers.")
                .font(TPDesign.bodyFont())
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
    }
    
    private func remixTrip(_ original: Travel) {
        // Clone logic: Map original to new Travel object and save to SwiftData
        let copy = Travel(name: "\(original.name) (Remix)", type: original.type)
        copy.status = .wishing
        // Map itineraries and spots...
        
        modelContext.insert(copy)
        // Show success alert
    }
}

struct TripResonanceCard: View {
    let travel: Travel
    let onRemix: () -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            // Placeholder/Snapshot of trip
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.tpAccent.opacity(0.1))
                .frame(height: 180)
                .overlay(
                    Image(systemName: "sparkles")
                        .font(.largeTitle)
                        .foregroundStyle(Color.tpAccent)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(travel.name)
                    .font(.headline)
                Text("\(travel.itineraries.count) Days · \(travel.spots.count) Spots")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 8)
            
            Button(action: onRemix) {
                Label("Remix", systemImage: "arrow.triangle.2.circlepath")
                    .font(.caption).bold()
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity)
                    .background(Color.tpAccent)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
            .padding(.top, 8)
        }
        .padding(12)
        .glassCard()
    }
}
