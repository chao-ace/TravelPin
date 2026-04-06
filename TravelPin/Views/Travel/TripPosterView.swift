import SwiftUI
import SwiftData

struct TripPosterView: View {
    let travel: Travel
    @State private var showExportSheet = false

    var body: some View {
        VStack(spacing: 0) {
            // Header Image/Icon Section
            ZStack(alignment: .bottomLeading) {
                LinearGradient(colors: [Color.tpAccent, Color.tpAccent.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .frame(height: 200)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text(travel.name)
                        .font(.system(size: 36, weight: .black, design: .serif))
                        .foregroundStyle(.white)
                    
                    HStack {
                        Text(travel.startDate.formatted(.dateTime.year().month().day()))
                        Text("—")
                        Text(travel.endDate.formatted(.dateTime.year().month().day()))
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white.opacity(0.9))
                }
                .padding(30)
            }
            
            // Statistics Bar
            HStack(spacing: 40) {
                VStack {
                    Text("\(travel.itineraries.count)")
                        .font(.title2).bold()
                    Text(locKey: "poster.stat.days").font(.caption).foregroundStyle(.secondary)
                }
                VStack {
                    Text("\(travel.spots.count)")
                        .font(.title2).bold()
                    Text(locKey: "poster.stat.spots").font(.caption).foregroundStyle(.secondary)
                }
                VStack {
                    Text("\(travel.type.displayName)")
                        .font(.title2).bold()
                    Text(locKey: "poster.stat.mood").font(.caption).foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 30)
            
            // Highlights Grid
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(locKey: "poster.highlights")
                        .font(TPDesign.titleFont(22))
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                        ForEach(travel.spots.prefix(4)) { spot in
                            VStack(alignment: .leading, spacing: 8) {
                                if let data = spot.photoData.first, let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 100)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                } else {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(.quaternary.opacity(0.3))
                                            .frame(height: 100)
                                        Image(systemName: spot.type.icon)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Text(spot.name)
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
                .padding()
            }
            
            Spacer()
            
            // Footer Brand
            HStack {
                Image(systemName: "pencil.and.outline")
                Text("TravelPin").bold()
                Spacer()
                Text(locKey: "poster.footer")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(20)
            .background(Color.tpSurface)
        }
        .background(.white)
        .navigationTitle("poster.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showExportSheet.toggle() }) {
                    Label("common.done".localized, systemImage: "square.and.arrow.up")
                }
            }
        }
        .sheet(isPresented: $showExportSheet) {
            PosterExportSheet(travel: travel)
        }
    }
}

#Preview {
    // Requires a mock travel object
    Text("Trip Poster Preview")
}
