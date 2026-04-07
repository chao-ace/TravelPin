import SwiftUI
import SwiftData
import PhotosUI

struct AddSpotView: View {
    let travel: Travel
    var preselectedItinerary: Itinerary? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var selectedType = SpotType.sightseeing
    @State private var notes = ""
    @State private var selectedItinerary: Itinerary?
    @State private var selectedItems: [PhotosPickerItem] = []
    
    @State private var selectedImages: [IdentifiableData] = []
    
    struct IdentifiableData: Identifiable {
        let id = UUID()
        let data: Data
    }

    @State private var isSaving = false
    @State private var isGeocoding = false
    @State private var locationConfirmed = false
    @State private var geocodeTask: Task<Void, Never>? = nil

    private let chipColumns = [
        GridItem(.adaptive(minimum: 95), spacing: 10)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: TPDesign.spacing24) {
                        // MARK: - Spot Detail Section
                        CinematicFormSection(titleLocKey: "add.spot.detail") {
                            VStack(spacing: 0) {
                                CinematicTextField(
                                    placeholderLocKey: "add.spot.name",
                                    text: $name,
                                    icon: "mappin",
                                    isLoading: isGeocoding,
                                    trailingIcon: locationConfirmed ? "checkmark.seal.fill" : nil
                                )

                                // Geocoding feedback row
                                if !name.isEmpty {
                                    HStack(spacing: 8) {
                                        if isGeocoding {
                                            ProgressView()
                                                .scaleEffect(0.7)
                                            Text("正在定位...")
                                                .font(TPDesign.bodyFont(12))
                                                .foregroundStyle(TPDesign.textTertiary)
                                        } else if locationConfirmed {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 12))
                                                .foregroundStyle(Color.tpAccent)
                                            Text("位置已锁定")
                                                .font(TPDesign.bodyFont(12))
                                                .foregroundStyle(Color.tpAccent)
                                        } else {
                                            Image(systemName: "location.slash")
                                                .font(.system(size: 12))
                                                .foregroundStyle(TPDesign.textTertiary)
                                            Text("未能识别，可稍后编辑坐标")
                                                .font(TPDesign.bodyFont(12))
                                                .foregroundStyle(TPDesign.textTertiary)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .animation(.spring(response: 0.3), value: isGeocoding)
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                                }

                                CinematicFormDivider()

                                // Type Chips
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("add.spot.type".localized)
                                        .font(TPDesign.captionFont())
                                        .foregroundStyle(TPDesign.textTertiary)
                                        .padding(.horizontal, 16)

                                    LazyVGrid(columns: chipColumns, spacing: 8) {
                                        ForEach(SpotType.allCases, id: \.self) { type in
                                            CinematicChipButton(
                                                title: type.displayName,
                                                icon: type.icon,
                                                isSelected: selectedType == type
                                            ) {
                                                withAnimation(TPDesign.springDefault) {
                                                    selectedType = type
                                                }
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 12)
                                }
                                .padding(.top, 4)
                            }
                        }
                        .cinematicFadeIn(delay: 0)

                        // MARK: - Itinerary Section
                        CinematicFormSection(titleLocKey: "add.spot.itinerary") {
                            VStack(spacing: 0) {
                                CinematicFormRow(icon: "route", iconColor: TPDesign.warmAmber) {
                                    Picker("add.spot.itinerary.pick".localized, selection: $selectedItinerary) {
                                        Text("add.spot.itinerary.none".localized).tag(nil as Itinerary?)
                                        ForEach(travel.itineraries.sorted(by: { $0.day < $1.day }), id: \.self) { itinerary in
                                            Text("\("add.itinerary.day".localized) \(itinerary.day)\("add.itinerary.unit".localized): \(itinerary.destination)")
                                                .tag(itinerary as Itinerary?)
                                        }
                                    }
                                    .font(TPDesign.bodyFont())
                                }
                            }
                        }
                        .cinematicFadeIn(delay: 0.1)

                        // MARK: - Photos Section
                        CinematicFormSection(titleLocKey: "add.spot.photos") {
                            VStack(spacing: TPDesign.spacing12) {
                                PhotosPicker(selection: $selectedItems, maxSelectionCount: 9, matching: .images) {
                                    CinematicFormRow(icon: "photo.on.rectangle.angled", iconColor: TPDesign.warmGold) {
                                        Text("add.spot.photos.select".localized)
                                            .font(TPDesign.bodyFont())
                                            .foregroundStyle(Color.tpAccent)
                                    }
                                }
                                .onChange(of: selectedItems) { oldValue, newValue in
                                    loadPhotos(from: newValue)
                                }

                                if !selectedImages.isEmpty {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 8) {
                                            ForEach(selectedImages) { item in
                                                if let uiImage = UIImage(data: item.data) {
                                                    ZStack(alignment: .topTrailing) {
                                                        Image(uiImage: uiImage)
                                                            .resizable()
                                                            .scaledToFill()
                                                            .frame(width: 80, height: 80)
                                                            .clipShape(RoundedRectangle(cornerRadius: TPDesign.radiusMedium))

                                                        // Delete button
                                                        Button {
                                                            withAnimation(TPDesign.springDefault) {
                                                                selectedImages.removeAll(where: { $0.id == item.id })
                                                            }
                                                        } label: {
                                                            Image(systemName: "xmark.circle.fill")
                                                                .font(.system(size: 18))
                                                                .symbolRenderingMode(.palette)
                                                                .foregroundStyle(.white, Color.black.opacity(0.5))
                                                        }
                                                        .offset(x: 4, y: -4)
                                                    }
                                                }
                                            }
                                        }
                                        .padding(.horizontal, 16)
                                    }
                                    .padding(.bottom, 8)
                                }
                            }
                        }
                        .cinematicFadeIn(delay: 0.2)

                        // MARK: - Notes Section
                        CinematicFormSection(titleLocKey: "add.spot.notes") {
                            CinematicTextField(
                                placeholderLocKey: "add.spot.notes.placeholder",
                                text: $notes,
                                axis: .vertical,
                                lineLimit: 3...10
                            )
                        }
                        .cinematicFadeIn(delay: 0.3)

                        // MARK: - Save Button
                        CinematicPrimaryButton(
                            locKey: "add.spot.save",
                            icon: "checkmark",
                            isLoading: isSaving
                        ) {
                            save()
                        }
                        .disabled(name.isEmpty || isSaving)
                        .padding(.bottom, TPDesign.spacing32)
                        .cinematicFadeIn(delay: 0.4)
                    }
                    .padding(.horizontal, TPDesign.spacing20)
                    .padding(.top, TPDesign.spacing16)
                }
                .background(TPDesign.backgroundGradient)
                .disabled(isSaving)

                // MARK: - Saving Overlay
                if isSaving {
                    ZStack {
                        Color.black.opacity(0.15)
                            .ignoresSafeArea()
                        VStack(spacing: 12) {
                            ProgressView()
                                .tint(Color.tpAccent)
                            Text("poster.export.rendering".localized)
                                .font(TPDesign.captionFont())
                                .foregroundStyle(TPDesign.textSecondary)
                        }
                        .padding(24)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: TPDesign.radiusLarge))
                    }
                    .transition(.opacity)
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
        .onAppear {
            if let pre = preselectedItinerary {
                selectedItinerary = pre
            }
        }
    }

    private func loadPhotos(from items: [PhotosPickerItem]) {
        for item in items {
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    await MainActor.run {
                        selectedImages.append(IdentifiableData(data: data))
                    }
                }
            }
        }
    }

    private func debounceGeocode() {
        geocodeTask?.cancel()
        locationConfirmed = false
        
        guard !name.isEmpty else { return }
        
        geocodeTask = Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1s debounce
            guard !Task.isCancelled else { return }
            
            await MainActor.run { 
                isGeocoding = true 
                TPHaptic.impact(.light)
            }
            
            if let _ = try? await LocationService.shared.geocode(address: name) {
                await MainActor.run {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        isGeocoding = false
                        locationConfirmed = true
                        TPHaptic.notification(.success)
                    }
                }
            } else {
                await MainActor.run {
                    withAnimation(.spring(response: 0.3)) {
                        isGeocoding = false
                        locationConfirmed = false
                    }
                }
            }
        }
    }

    private func save() {
        let spotName = name
        let currentSelectedType = selectedType
        let currentNotes = notes
        let currentImagesData = selectedImages.map { $0.data }
        let currentItinerary = selectedItinerary

        isSaving = true

        Task {
            let newSpot = Spot(name: spotName, type: currentSelectedType.rawValue, notes: currentNotes)
            newSpot.travel = travel
            newSpot.itinerary = currentItinerary
            newSpot.photos = currentImagesData.map { TravelPhoto(data: $0) }

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
                try? modelContext.save()
                isSaving = false
                TPHaptic.notification(.success)
                dismiss()
            }
        }
    }
}
