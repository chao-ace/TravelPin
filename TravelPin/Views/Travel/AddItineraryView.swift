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
                Stepper("\("add.itinerary.day".localized) \(day)\("add.itinerary.unit".localized)", value: $day, in: 1...31)
                TextField("add.itinerary.origin".localized, text: $origin)
                TextField("add.itinerary.destination".localized, text: $destination)
            }
            .navigationTitle("add.itinerary.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel".localized) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("add.itinerary.add".localized) {
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
