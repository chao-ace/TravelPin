import SwiftUI
import SwiftData

struct AddTravelView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var name = ""
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(86400 * 3)
    @State private var selectedStatus = TravelStatus.wishing
    @State private var selectedType = TravelType.tourism
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(locKey: "add.travel.info")) {
                    TextField("add.travel.name".localized, text: $name)
                        .font(TPDesign.bodyFont(20))
                    
                    Picker("add.travel.type".localized, selection: $selectedType) {
                        ForEach(TravelType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: type.icon)
                                Text(type.rawValue)
                            }
                            .tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section(header: Text(locKey: "add.travel.dates")) {
                    DatePicker("add.travel.start".localized, selection: $startDate, displayedComponents: .date)
                    DatePicker("add.travel.end".localized, selection: $endDate, displayedComponents: .date)
                }
                
                Section(header: Text(locKey: "add.travel.status")) {
                    Picker("add.travel.status".localized, selection: $selectedStatus) {
                        ForEach(TravelStatus.allCases, id: \.self) { status in
                            Text(status.rawValue).tag(status)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("add.travel.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel".localized) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("add.travel.create".localized) {
                        saveTravel()
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func saveTravel() {
        let newTravel = Travel(
            name: name,
            startDate: startDate,
            endDate: endDate,
            status: selectedStatus,
            type: selectedType
        )
        modelContext.insert(newTravel)
    }
}

#Preview {
    AddTravelView()
}
