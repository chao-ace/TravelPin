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
    
    // Photo Selection
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedImagesData: [Data] = []
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Spot Detail")) {
                    TextField("Spot Name", text: $name)
                    Picker("Visit Type", selection: $selectedType) {
                        ForEach(SpotType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: type.icon)
                                Text(type.rawValue)
                            }.tag(type)
                        }
                    }
                }
                
                Section(header: Text("Connected Itinerary")) {
                    Picker("Associate with Day", selection: $selectedItinerary) {
                        Text("Unassigned").tag(nil as Itinerary?)
                        ForEach(travel.itineraries.sorted(by: { $0.day < $1.day }), id: \.self) { itinerary in
                            Text("Day \(itinerary.day): \(itinerary.destination)").tag(itinerary as Itinerary?)
                        }
                    }
                }
                
                Section(header: Text("Photos")) {
                    PhotosPicker(selection: $selectedItems, maxSelectionCount: 9, matching: .images) {
                        Label("Select Photos", systemImage: "photo.on.rectangle.angled")
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
                
                Section(header: Text("Notes")) {
                    TextField("Recommendation, feelings, etc.", text: $notes, axis: .vertical)
                        .lineLimit(3...10)
                }
            }
            .navigationTitle("New Highlight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                        dismiss()
                    }
                    .disabled(name.isEmpty)
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
            }
        }
    }
}
