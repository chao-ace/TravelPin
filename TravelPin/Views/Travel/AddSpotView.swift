import SwiftUI
import SwiftData
import PhotosUI

struct AddSpotView: View {
    let travel: Travel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var name = ""
    @State private var selectedType = SpotType.sightseeing
    @State private var notes = ""
    @State private var selectedItinerary: Itinerary?
    
    @State private var isSaving = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Form {
                    Section(header: Text(locKey: "add.spot.detail")) {
                        TextField("add.spot.name".localized, text: $name)
                        Picker("add.spot.type".localized, selection: $selectedType) {
                            ForEach(SpotType.allCases, id: \.self) { type in
                                HStack {
                                    Image(systemName: type.icon)
                                    Text(type.rawValue)
                                }.tag(type)
                            }
                        }
                    }
                    
                    Section(header: Text(locKey: "add.spot.itinerary")) {
                        Picker("add.spot.itinerary.pick".localized, selection: $selectedItinerary) {
                            Text("add.spot.itinerary.none".localized).tag(nil as Itinerary?)
                            ForEach(travel.itineraries.sorted(by: { $0.day < $1.day }), id: \.self) { itinerary in
                                Text("\("add.itinerary.day".localized) \(itinerary.day)\("add.itinerary.unit".localized): \(itinerary.destination)").tag(itinerary as Itinerary?)
                            }
                        }
                    }
                    
                    Section(header: Text(locKey: "add.spot.photos")) {
                        PhotosPicker(selection: $selectedItems, maxSelectionCount: 9, matching: .images) {
                            Label("add.spot.photos.select".localized, systemImage: "photo.on.rectangle.angled")
                                .foregroundStyle(Color.tpAccent)
                        }
                        .onChange(of: selectedItems) { oldValue, newValue in
                            loadPhotos(from: newValue)
                        }
                        
                        if !selectedImagesData.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(selectedImagesData, id: \.self) { data in
                                        if let uiImage = UIImage(data: data) {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 80, height: 80)
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                        }
                                    }
                                }
                            }
                            .frame(height: 80)
                        }
                    }
                    
                    Section(header: Text(locKey: "add.spot.notes")) {
                        TextField("add.spot.notes.placeholder".localized, text: $notes, axis: .vertical)
                            .lineLimit(3...10)
                    }
                }
                .disabled(isSaving)
                
                if isSaving {
                    ZStack {
                        Color.black.opacity(0.1)
                            .ignoresSafeArea()
                        VStack(spacing: 12) {
                            ProgressView()
                                .tint(Color.tpAccent)
                            Text("poster.export.rendering".localized)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(20)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                }
            }
            .navigationTitle("add.spot.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel".localized) { dismiss() }
                        .disabled(isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("add.spot.save".localized) {
                        save()
                    }
                    .disabled(name.isEmpty || isSaving)
                }
            }
        }
    }
    
    private func loadPhotos(from items: [PhotosPickerItem]) {
        selectedImagesData = []
        for item in items {
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    await MainActor.run {
                        selectedImagesData.append(data)
                    }
                }
            }
        }
    }
    
    private func save() {
        let spotName = name
        let currentSelectedType = selectedType
        let currentNotes = notes
        let currentImagesData = selectedImagesData
        let currentItinerary = selectedItinerary

        isSaving = true
        
        Task {
            let newSpot = Spot(name: spotName, type: currentSelectedType, notes: currentNotes)
            newSpot.travel = travel
            newSpot.itinerary = currentItinerary
            newSpot.photoData = currentImagesData
            
            // Geocode
            do {
                if let coordinate = try await LocationService.shared.geocode(address: spotName) {
                    await MainActor.run {
                        newSpot.latitude = coordinate.latitude
                        newSpot.longitude = coordinate.longitude
                    }
                }
            } catch {
                print("Geocoding failed: \(error)")
                // Fallback: use a random offset from origin if geocode fails for demo purposes
                await MainActor.run {
                    newSpot.latitude = 48.8566 + Double.random(in: -0.1...0.1)
                    newSpot.longitude = 2.3522 + Double.random(in: -0.1...0.1)
                }
            }
            
            // Map Snapshot
            if let coordinate = newSpot.coordinate {
                if let snapshotData = try? await MapCacheService.shared.generateSnapshot(for: coordinate) {
                    await MainActor.run {
                        newSpot.mapSnapshot = snapshotData
                    }
                }
            }
            
            await MainActor.run {
                modelContext.insert(newSpot)
                // Explicitly save the context to ensure persistence closure
                try? modelContext.save()
                isSaving = false
                dismiss()
            }
        }
    }
}
}
