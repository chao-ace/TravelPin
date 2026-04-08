import SwiftUI
import SwiftData

struct EditSpotView: View {
    @Bindable var spot: Spot
    let travel: Travel
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var name: String
    @State private var selectedType: SpotType
    @State private var notes: String
    @State private var selectedItinerary: Itinerary?
    
    @State private var isSaving = false
    @State private var isGeocoding = false
    @State private var locationConfirmed = false
    
    @State private var status: SpotStatus
    
    init(spot: Spot, travel: Travel) {
        self.spot = spot
        self.travel = travel
        _name = State(initialValue: spot.name)
        _selectedType = State(initialValue: spot.type)
        _notes = State(initialValue: spot.notes)
        _selectedItinerary = State(initialValue: spot.itinerary)
        _status = State(initialValue: spot.status)
    }
    
    private let chipColumns = [
        GridItem(.adaptive(minimum: 95), spacing: 10)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: TPDesign.spacing24) {
                        // Visit State
                        CinematicFormSection(titleLocKey: "add.spot.status") {
                            HStack {
                                CinematicChipButton(
                                    title: "footprint.stat.visited_short".localized,
                                    icon: "checkmark.circle.fill",
                                    isSelected: status == .travelled
                                ) {
                                    withAnimation {
                                        status = status == .travelled ? .planning : .travelled
                                        TPHaptic.selection()
                                    }
                                }
                                Spacer()
                            }
                            .padding(16)
                        }

                        // Details
                        CinematicFormSection(titleLocKey: "add.spot.detail") {
                            VStack(spacing: 0) {
                                CinematicTextField(
                                    placeholderLocKey: "add.spot.name",
                                    text: $name,
                                    icon: "mappin",
                                    isLoading: isGeocoding,
                                    trailingIcon: locationConfirmed ? "checkmark.seal.fill" : nil
                                )
                                
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
                        
                        // Itinerary
                        CinematicFormSection(titleLocKey: "add.spot.itinerary") {
                            VStack(spacing: 0) {
                                CinematicFormRow(icon: "route", iconColor: TPDesign.warmAmber) {
                                    Picker("add.spot.itinerary.pick".localized, selection: $selectedItinerary) {
                                        Text("add.spot.itinerary.none".localized).tag(nil as Itinerary?)
                                        ForEach(travel.itineraries.sorted(by: { $0.day < $1.day }), id: \.self) { it in
                                            Text("\("add.itinerary.day".localized) \(it.day)\("add.itinerary.unit".localized): \(it.destination)").tag(it as Itinerary?)
                                        }
                                    }
                                    .font(TPDesign.bodyFont())
                                }
                            }
                        }
                        
                        // Notes
                        CinematicFormSection(titleLocKey: "add.spot.notes") {
                            CinematicTextField(
                                placeholderLocKey: "add.spot.notes.placeholder",
                                text: $notes,
                                axis: .vertical,
                                lineLimit: 3...10
                            )
                        }
                        
                        // Actions
                        VStack(spacing: 12) {
                            Button(role: .destructive) {
                                TPHaptic.notification(.warning)
                                deleteSpot()
                            } label: {
                                Text("删除此地点")
                                    .font(TPDesign.bodyFont(16).weight(.bold))
                                    .foregroundStyle(.red)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.red.opacity(0.08))
                                    .clipShape(Capsule())
                                    .overlay(Capsule().stroke(Color.red.opacity(0.1), lineWidth: 1))
                            }
                        }
                        .padding(.top, 20)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                }
                .background(TPDesign.backgroundGradient)
                .navigationTitle("编辑地点")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("common.cancel".localized) { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("add.spot.save".localized) { save() }
                            .disabled(name.isEmpty || isSaving)
                    }
                }
            }
        }
    }
    
    private func save() {
        isSaving = true
        spot.name = name
        spot.typeRaw = selectedType.rawValue
        spot.notes = notes
        spot.itinerary = selectedItinerary
        spot.statusRaw = status.rawValue
        
        try? modelContext.save()
        
        // Update live activity if running
        if let it = spot.itinerary {
            let daySpots = it.spots
            let completed = daySpots.filter { $0.status == .travelled }.count
            LiveActivityManager.shared.updateActivity(
                completedSpots: completed,
                totalSpots: daySpots.count,
                currentSpotName: spot.name
            )
        }
        
        TPHaptic.notification(.success)
        dismiss()
    }
    
    private func deleteSpot() {
        modelContext.delete(spot)
        try? modelContext.save()
        dismiss()
    }
}
