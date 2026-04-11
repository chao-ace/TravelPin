import SwiftUI
import SwiftData
import PhotosUI

struct EditTravelView: View {
    @Bindable var travel: Travel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var newCompanion = ""
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var budgetText: String = ""
    @State private var selectedCurrency: String = "CNY"
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(locKey: "edit.travel.info")) {
                    TextField("add.travel.name".localized, text: $travel.name)
                        .font(TPDesign.bodyFont(20))
                    
                    Picker("add.travel.type".localized, selection: $travel.type) {
                        ForEach(TravelType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: type.icon)
                                Text(type.displayName)
                            }
                            .tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section(header: Text(locKey: "add.travel.dates")) {
                    DatePicker("add.travel.start".localized, selection: $travel.startDate, displayedComponents: .date)
                    DatePicker("add.travel.end".localized, selection: $travel.endDate, displayedComponents: .date)
                }
                
                Section(header: Text(locKey: "add.travel.status")) {
                    Picker("add.travel.status".localized, selection: $travel.status) {
                        ForEach(TravelStatus.allCases, id: \.self) { status in
                            Text(status.displayName).tag(status)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section(header: Text(locKey: "add.travel.budget")) {
                    HStack {
                        TextField("add.travel.budget.placeholder".localized, text: $budgetText)
                            .font(TPDesign.bodyFont())
                            .keyboardType(.decimalPad)

                        Picker("", selection: $selectedCurrency) {
                            ForEach(["CNY", "USD", "EUR", "JPY", "GBP"], id: \.self) { code in
                                Text(code).tag(code)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                    }
                }

                Section(header: Text(locKey: "add.travel.calendar")) {
                    if let eventId = travel.calendarEventId, !eventId.isEmpty {
                        Label("add.travel.calendar_synced".localized, systemImage: "calendar.badge.checkmark")
                            .foregroundStyle(Color.tpAccent)
                    } else {
                        Button {
                            Task {
                                if let eventId = await CalendarSyncService.shared.createEvent(for: travel) {
                                    travel.calendarEventId = eventId
                                    try? modelContext.save()
                                }
                            }
                        } label: {
                            Label("add.travel.calendar_sync".localized, systemImage: "calendar.badge.plus")
                                .foregroundStyle(Color.tpAccent)
                        }
                    }
                }

                Section(header: Text(locKey: "edit.travel.companions")) {
                    ForEach(travel.companionNames, id: \.self) { name in
                        Text(name)
                    }
                    .onDelete { indexSet in
                        travel.companionNames.remove(atOffsets: indexSet)
                    }
                    
                    HStack {
                        TextField("companion.placeholder".localized, text: $newCompanion)
                        Button(action: addCompanion) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(Color.tpAccent)
                        }
                        .disabled(newCompanion.isEmpty)
                    }
                }
                
                Section(header: Text(locKey: "edit.travel.photos")) {
                    PhotosPicker(selection: $selectedItems, maxSelectionCount: 9, matching: .images) {
                        Label("edit.travel.add_photo".localized, systemImage: "photo.on.rectangle.angled")
                            .foregroundStyle(Color.tpAccent)
                    }
                    .onChange(of: selectedItems) { oldValue, newValue in
                        loadPhotos(from: newValue)
                    }
                    
                    let allPhotos = travel.spots.flatMap { $0.photos }
                    if !allPhotos.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(allPhotos) { photo in
                                    if let data = photo.data, let uiImage = UIImage(data: data) {
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
            }
            .navigationTitle("edit.travel.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if let budget = travel.budget {
                    budgetText = String(format: "%.0f", budget)
                }
                selectedCurrency = travel.currency
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.done".localized) {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func addCompanion() {
        withAnimation {
            travel.companionNames.append(newCompanion)
            newCompanion = ""
        }
    }
    
    private func loadPhotos(from items: [PhotosPickerItem]) {
        // We find or create a "Highlights" spot to anchor these general photos
        let highlightsSpot: Spot = {
            if let existing = travel.spots.first(where: { $0.name == "Journey Highlights".localized }) {
                return existing
            }
            let newSpot = Spot(name: "Journey Highlights".localized, type: SpotType.sightseeing.rawValue, notes: "General trip photos")
            newSpot.travel = travel
            travel.spots.append(newSpot)
            return newSpot
        }()

        for item in items {
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    await MainActor.run {
                        let photo = TravelPhoto(data: data)
                        photo.spot = highlightsSpot
                        highlightsSpot.photos.append(photo)
                    }
                }
            }
        }
    }
}
