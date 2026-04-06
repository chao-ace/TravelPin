import SwiftUI
import SwiftData

struct InspirationPlazaView: View {
    @State private var publicTrips: [Travel] = MockDataCenter.getPublicTrips()
    @Environment(\.modelContext) private var modelContext
    @State private var showingSuccessToast = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        headerSection
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                            ForEach(publicTrips) { trip in
                                TripResonanceCard(travel: trip) {
                                    remixTrip(trip)
                                }
                            }
                        }
                        .padding()
                    }
                }
                
                if showingSuccessToast {
                    VStack {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("common.done".localized)
                                .font(.headline)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .shadow(radius: 10)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.top, 50)
                        Spacer()
                    }
                }
            }
            .navigationTitle("inspiration.title".localized)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("inspiration.header".localized)
                .font(TPDesign.titleFont(32))
            Text("inspiration.subtitle".localized)
                .font(TPDesign.bodyFont())
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
        .padding(.top, 20)
    }

    private func remixTrip(_ original: Travel) {
        let copy = MockDataCenter.deepClone(travel: original)
        modelContext.insert(copy)
        
        withAnimation(.spring()) {
            showingSuccessToast = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showingSuccessToast = false
            }
        }
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
                Text("\(travel.itineraries.count) \("common.days".localized) · \(travel.spots.count) \("common.spots".localized)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 8)
            
            Button(action: onRemix) {
                Label("discover.card.remix".localized, systemImage: "arrow.triangle.2.circlepath")
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
