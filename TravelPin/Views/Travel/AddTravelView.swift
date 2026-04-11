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
    @State private var budgetText = ""
    @State private var selectedCurrency = "CNY"
    @State private var syncToCalendar = false

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: TPDesign.spacing24) {
                    // MARK: - Basic Info Section
                    CinematicFormSection(titleLocKey: "add.travel.info") {
                        VStack(spacing: 0) {
                            CinematicTextField(
                                placeholderLocKey: "add.travel.name",
                                text: $name,
                                icon: "pencil.and.outline"
                            )

                            CinematicFormDivider()

                            // Type Chips
                            CinematicFormRow(icon: "tag", iconColor: TPDesign.warmAmber) {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(TravelType.allCases, id: \.self) { type in
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
                                }
                            }
                        }
                    }
                    .cinematicFadeIn(delay: 0)

                    // MARK: - Dates Section
                    CinematicFormSection(titleLocKey: "add.travel.dates") {
                        VStack(spacing: 0) {
                            CinematicFormRow(icon: "calendar", iconColor: .tpAccent) {
                                DatePicker(
                                    "add.travel.start".localized,
                                    selection: $startDate,
                                    displayedComponents: .date
                                )
                                .font(TPDesign.bodyFont())
                            }

                            CinematicFormDivider()

                            CinematicFormRow(icon: "calendar.badge.clock", iconColor: TPDesign.warmGold) {
                                DatePicker(
                                    "add.travel.end".localized,
                                    selection: $endDate,
                                    displayedComponents: .date
                                )
                                .font(TPDesign.bodyFont())
                            }
                        }
                    }
                    .cinematicFadeIn(delay: 0.1)

                    // MARK: - Budget Section
                    CinematicFormSection(titleLocKey: "add.travel.budget") {
                        VStack(spacing: 0) {
                            CinematicFormRow(icon: "yensign.circle", iconColor: TPDesign.warmGold) {
                                HStack(spacing: 8) {
                                    TextField("add.travel.budget.placeholder".localized, text: $budgetText)
                                        .font(TPDesign.bodyFont())
                                        .keyboardType(.decimalPad)

                                    // Currency Picker
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 6) {
                                            ForEach(["CNY", "USD", "EUR", "JPY", "GBP"], id: \.self) { code in
                                                CinematicChipButton(
                                                    title: code,
                                                    icon: nil,
                                                    isSelected: selectedCurrency == code
                                                ) {
                                                    withAnimation(TPDesign.springDefault) {
                                                        selectedCurrency = code
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .cinematicFadeIn(delay: 0.15)

                    // MARK: - Calendar Sync Section
                    CinematicFormSection(titleLocKey: "add.travel.calendar") {
                        VStack(spacing: 0) {
                            CinematicFormRow(icon: "calendar.badge.plus", iconColor: TPDesign.celestialBlue) {
                                Toggle("add.travel.calendar_sync".localized, isOn: $syncToCalendar)
                                    .font(TPDesign.bodyFont())
                                    .tint(Color.tpAccent)
                            }
                        }
                    }
                    .cinematicFadeIn(delay: 0.18)

                    // MARK: - Status Section
                    CinematicFormSection(titleLocKey: "add.travel.status") {
                        VStack(spacing: 0) {
                            PaddingRow {
                                CinematicSegmentedPicker(
                                    options: TravelStatus.allCases,
                                    selection: $selectedStatus,
                                    labelFor: { $0.displayName }
                                )
                            }
                        }
                    }
                    .cinematicFadeIn(delay: 0.2)

                    // MARK: - Action Buttons
                    VStack(spacing: TPDesign.spacing12) {
                        CinematicPrimaryButton(
                            locKey: "add.travel.create",
                            icon: "paperplane.fill"
                        ) {
                            saveTravel()
                            dismiss()
                        }
                        .disabled(name.isEmpty)

                        CinematicSecondaryButton(
                            locKey: "common.cancel"
                        ) {
                            dismiss()
                        }
                    }
                    .padding(.top, TPDesign.spacing8)
                    .padding(.bottom, TPDesign.spacing32)
                    .cinematicFadeIn(delay: 0.3)
                }
                .padding(.horizontal, TPDesign.spacing20)
                .padding(.top, TPDesign.spacing16)
            }
            .background(TPDesign.backgroundGradient)
            .navigationTitle("add.travel.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel".localized) { dismiss() }
                }
            }
        }
    }

    private func saveTravel() {
        let newTravel = Travel(
            name: name,
            startDate: startDate,
            endDate: endDate,
            status: selectedStatus.rawValue,
            type: selectedType.rawValue
        )

        // Budget
        if let budget = Double(budgetText), budget > 0 {
            newTravel.budget = budget
            newTravel.currency = selectedCurrency
        }

        modelContext.insert(newTravel)

        // Finalize buffered operations to ensure data appears immediately in @Query
        try? modelContext.processPendingChanges()
        try? modelContext.save()
        TPHaptic.notification(.success)

        // Schedule notifications for future trips
        if startDate > Date() {
            Task {
                await NotificationService.shared.scheduleTripReminder(for: newTravel)
                await NotificationService.shared.schedulePackingReminder(for: newTravel)
            }
        }

        // Calendar sync
        if syncToCalendar {
            Task {
                if let eventId = await CalendarSyncService.shared.createEvent(for: newTravel) {
                    newTravel.calendarEventId = eventId
                    try? modelContext.save()
                }
            }
        }
    }
}

// MARK: - Padding Helper Row

private struct PaddingRow<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        HStack {
            content()
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

#Preview {
    AddTravelView()
}
