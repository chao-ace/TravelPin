import SwiftUI
import SwiftData

/// Multi-step wizard for creating a new travel.
/// Replaces the single-page AddTravelView with a guided flow:
/// Step 1 → Name & Type | Step 2 → Dates | Step 3 → Budget | Step 4 → Preview & Create
struct AddTravelWizardView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var currentStep = 0
    @State private var name = ""
    @State private var selectedType = TravelType.tourism
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(86400 * 3)
    @State private var budgetText = ""
    @State private var selectedCurrency = "CNY"
    @State private var budgetBreakdown: [String: Double] = [:]
    @State private var syncToCalendar = false
    @State private var recommendedType: TravelType? = nil

    private let totalSteps = 4

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress bar
                wizardProgressBar

                // Step content
                TabView(selection: $currentStep) {
                    WizardStepNameType(
                        name: $name,
                        selectedType: $selectedType,
                        recommendedType: recommendedType
                    ).tag(0)

                    WizardStepDates(
                        startDate: $startDate,
                        endDate: $endDate
                    ).tag(1)

                    WizardStepBudget(
                        budgetText: $budgetText,
                        selectedCurrency: $selectedCurrency,
                        budgetBreakdown: $budgetBreakdown,
                        travelType: selectedType
                    ).tag(2)

                    WizardStepPreview(
                        name: name,
                        selectedType: selectedType,
                        startDate: startDate,
                        endDate: endDate,
                        budgetText: budgetText,
                        selectedCurrency: selectedCurrency,
                        budgetBreakdown: budgetBreakdown
                    ).tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(TPDesign.springDefault, value: currentStep)

                // Navigation buttons
                wizardNavigationBar
            }
            .background(TPDesign.backgroundGradient)
            .navigationTitle(locKey: "wizard.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel".localized) { dismiss() }
                }
            }
            .onAppear {
                // Detect recommended type from TravelDNA
                detectRecommendedType()
            }
        }
    }

    // MARK: - Progress Bar

    private var wizardProgressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(TPDesign.alabaster.opacity(0.3))
                    .frame(height: 3)

                Rectangle()
                    .fill(TPDesign.accentGradient)
                    .frame(
                        width: geo.size.width * CGFloat(currentStep + 1) / CGFloat(totalSteps),
                        height: 3
                    )
                    .animation(TPDesign.springDefault, value: currentStep)
            }
        }
        .frame(height: 3)
        .padding(.top, 8)
    }

    // MARK: - Navigation Bar

    private var wizardNavigationBar: some View {
        VStack(spacing: 0) {
            Divider()
                .foregroundStyle(.quaternary)

            HStack(spacing: 16) {
                // Back button
                if currentStep > 0 {
                    CinematicSecondaryButton(locKey: "wizard.back") {
                        withAnimation(TPDesign.springDefault) {
                            currentStep -= 1
                        }
                    }
                }

                // Next / Create button
                if currentStep < totalSteps - 1 {
                    CinematicPrimaryButton(
                        locKey: "wizard.next",
                        icon: "arrow.right"
                    ) {
                        withAnimation(TPDesign.springDefault) {
                            currentStep += 1
                        }
                    }
                    .disabled(!canProceed)
                    .opacity(canProceed ? 1 : 0.5)
                } else {
                    CinematicPrimaryButton(
                        locKey: "wizard.create",
                        icon: "paperplane.fill"
                    ) {
                        saveTravel()
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                    .opacity(name.isEmpty ? 0.5 : 1)

                    // Calendar sync toggle on final step
                    Toggle("add.travel.calendar_sync".localized, isOn: $syncToCalendar)
                        .font(TPDesign.captionFont())
                        .tint(Color.tpAccent)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(TPDesign.background)
        }
    }

    // MARK: - Validation

    private var canProceed: Bool {
        switch currentStep {
        case 0:
            return !name.isEmpty
        case 1:
            return endDate >= startDate
        case 2:
            return true // Budget is optional
        default:
            return true
        }
    }

    // MARK: - Save

    private func saveTravel() {
        let newTravel = Travel(
            name: name,
            startDate: startDate,
            endDate: endDate,
            status: TravelStatus.planning.rawValue,
            type: selectedType.rawValue
        )

        // Budget
        if let budget = Double(budgetText), budget > 0 {
            newTravel.budget = budget
            newTravel.currency = selectedCurrency
        }

        // Budget breakdown
        if !budgetBreakdown.isEmpty {
            newTravel.budgetBreakdown = budgetBreakdown
        }

        modelContext.insert(newTravel)
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

    // MARK: - Smart Recommendations

    private func detectRecommendedType() {
        // Query all travels to find the user's most common type
        let descriptor = FetchDescriptor<Travel>(sortBy: [SortDescriptor(\Travel.startDate, order: .reverse)])
        let travels = (try? modelContext.fetch(descriptor)) ?? []
        guard !travels.isEmpty else { return }

        let typeCounts = Dictionary(grouping: travels) { $0.type }
        let dominant = typeCounts.max { $0.value.count < $1.value.count }
        if let dominantType = dominant?.key, typeCounts[dominantType]!.count >= 2 {
            recommendedType = dominantType
        }
    }
}
