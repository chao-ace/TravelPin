import SwiftUI
import SwiftData

struct EditItineraryView: View {
    @Bindable var itinerary: Itinerary
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var day: Int
    @State private var origin: String
    @State private var destination: String
    
    init(itinerary: Itinerary) {
        self.itinerary = itinerary
        _day = State(initialValue: itinerary.day)
        _origin = State(initialValue: itinerary.origin)
        _destination = State(initialValue: itinerary.destination)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: TPDesign.spacing32) {
                    // Day Selector
                    VStack(spacing: TPDesign.spacing8) {
                        Text("add.itinerary.day.title".localized)
                            .font(TPDesign.overline())
                            .foregroundStyle(TPDesign.textTertiary)
                            .tracking(2)

                        HStack(spacing: TPDesign.spacing24) {
                            Button {
                                if day > 1 { day -= 1; TPHaptic.selection() }
                            } label: {
                                Image(systemName: "minus.circle").font(.system(size: 28)).foregroundStyle(day > 1 ? Color.tpAccent : TPDesign.textTertiary)
                            }
                            
                            Text("\(day)")
                                .font(TPDesign.cinematicTitle(48))
                                .foregroundStyle(TPDesign.textPrimary)
                                .frame(minWidth: 80)
                            
                            Button {
                                if day < 31 { day += 1; TPHaptic.selection() }
                            } label: {
                                Image(systemName: "plus.circle").font(.system(size: 28)).foregroundStyle(Color.tpAccent)
                            }
                        }
                    }
                    .padding(.vertical, 16)
                    
                    // Route
                    CinematicFormSection(titleLocKey: "add.itinerary.cities") {
                        HStack(spacing: 12) {
                            CinematicTextField(placeholderLocKey: "add.itinerary.origin", text: $origin, icon: "location.fill")
                            Image(systemName: "arrow.right").font(.system(size: 14, weight: .bold)).foregroundStyle(Color.tpAccent)
                            CinematicTextField(placeholderLocKey: "add.itinerary.destination", text: $destination, icon: "mappin.and.ellipse")
                        }
                    }
                    
                    // Actions
                    VStack(spacing: 12) {
                        Button {
                            save()
                        } label: {
                            Text("common.done".localized)
                                .font(TPDesign.bodyFont(16).weight(.bold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(TPDesign.brandGradient)
                                .clipShape(Capsule())
                                .shadowSmall()
                        }
                        .disabled(origin.isEmpty || destination.isEmpty)
                        
                        Button(role: .destructive) {
                            TPHaptic.notification(.warning)
                            delete()
                        } label: {
                            Text("common.delete".localized)
                                .font(TPDesign.bodyFont(16))
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.red.opacity(0.08))
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.top, 24)
                    .padding(.horizontal, 20)
                }
                .padding(.top, 24)
            }
            .background(TPDesign.backgroundGradient)
            .navigationTitle("edit.itinerary.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel".localized) { dismiss() }
                }
            }
        }
    }
    
    private func save() {
        itinerary.day = day
        itinerary.origin = origin
        itinerary.destination = destination
        try? modelContext.save()
        TPHaptic.notification(.success)
        dismiss()
    }
    
    private func delete() {
        modelContext.delete(itinerary)
        try? modelContext.save()
        dismiss()
    }
}
