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
                Section(header: Text("Basic Information")) {
                    TextField("Travel Name", text: $name)
                        .font(TPDesign.bodyFont(20))
                    
                    Picker("Travel Type", selection: $selectedType) {
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
                
                Section(header: Text("Dates")) {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                }
                
                Section(header: Text("Status")) {
                    Picker("Current Status", selection: $selectedStatus) {
                        ForEach(TravelStatus.allCases, id: \.self) { status in
                            Text(status.rawValue).tag(status)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("New Journey")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
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
