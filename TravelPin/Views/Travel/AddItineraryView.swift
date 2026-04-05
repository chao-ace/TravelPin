import SwiftUI
import SwiftData

struct AddItineraryView: View {
    let travel: Travel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var day = 1
    @State private var origin = ""
    @State private var destination = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Stepper("Day \(day)", value: $day, in: 1...31)
                TextField("Origin City", text: $origin)
                TextField("Destination City", text: $destination)
            }
            .navigationTitle("Add Daily Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        save()
                        dismiss()
                    }
                    .disabled(origin.isEmpty || destination.isEmpty)
                }
            }
        }
    }
    
    private func save() {
        let newItinerary = Itinerary(day: day, origin: origin, destination: destination)
        newItinerary.travel = travel
        modelContext.insert(newItinerary)
    }
}
