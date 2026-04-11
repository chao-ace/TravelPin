import SwiftUI

/// Step 2: Date selection with quick presets.
struct WizardStepDates: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    @State private var selectedPreset: DatePreset? = nil

    enum DatePreset: String, CaseIterable {
        case thisWeekend
        case nextWeek
        case nextMonth
        case custom

        var displayName: String {
            "wizard.dates.\(self.rawValue)".localized
        }

        var icon: String {
            switch self {
            case .thisWeekend: return "sun.haze"
            case .nextWeek:    return "calendar.badge.clock"
            case .nextMonth:   return "calendar.badge.plus"
            case .custom:      return "slider.horizontal.3"
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            // Section header
            VStack(alignment: .leading, spacing: 8) {
                Text(locKey: "wizard.step2.title")
                    .font(TPDesign.editorialSerif(28))
                    .foregroundStyle(TPDesign.obsidian)
                Text(locKey: "wizard.step2.subtitle")
                    .font(TPDesign.bodyFont(14))
                    .foregroundStyle(.secondary)
            }

            // Quick presets
            CinematicFormSection(titleLocKey: "wizard.step2.quick") {
                VStack(spacing: 8) {
                    ForEach(DatePreset.allCases, id: \.self) { preset in
                        Button {
                            withAnimation(TPDesign.springDefault) {
                                selectedPreset = preset
                                applyPreset(preset)
                            }
                        } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(selectedPreset == preset ? Color.tpAccent.opacity(0.15) : TPDesign.alabaster)
                                        .frame(width: 40, height: 40)
                                    Image(systemName: preset.icon)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(selectedPreset == preset ? Color.tpAccent : .secondary)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(preset.displayName)
                                        .font(TPDesign.bodyFont(15, weight: selectedPreset == preset ? .bold : .regular))
                                        .foregroundStyle(selectedPreset == preset ? TPDesign.obsidian : .secondary)
                                    if preset != .custom {
                                        Text(presetDatePreview(preset))
                                            .font(TPDesign.captionFont())
                                            .foregroundStyle(.tertiary)
                                    }
                                }

                                Spacer()

                                if selectedPreset == preset {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundStyle(Color.tpAccent)
                                }
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(selectedPreset == preset ? Color.tpAccent.opacity(0.05) : .clear)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(selectedPreset == preset ? Color.tpAccent.opacity(0.3) : .clear, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Custom date pickers (visible when custom is selected)
            if selectedPreset == .custom {
                CinematicFormSection(titleLocKey: "wizard.step2.custom") {
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
                                in: startDate...,
                                displayedComponents: .date
                            )
                            .font(TPDesign.bodyFont())
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // Duration display
            let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: startDate), to: Calendar.current.startOfDay(for: endDate)).day ?? 0
            HStack {
                Image(systemName: "clock")
                    .foregroundStyle(.secondary)
                Text(String(format: "wizard.step2.duration".localized, days + 1))
                    .font(TPDesign.bodyFont(14, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 4)

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private func applyPreset(_ preset: DatePreset) {
        let calendar = Calendar.current
        let today = Date()

        switch preset {
        case .thisWeekend:
            // Find next Saturday
            var nextSat = today
            while calendar.component(.weekday, from: nextSat) != 7 {
                nextSat = calendar.date(byAdding: .day, value: 1, to: nextSat)!
            }
            startDate = nextSat
            endDate = calendar.date(byAdding: .day, value: 1, to: nextSat)!

        case .nextWeek:
            let nextMonday = calendar.date(byAdding: .weekOfYear, value: 1, to: calendar.startOfDay(for: today))!
            startDate = nextMonday
            endDate = calendar.date(byAdding: .day, value: 4, to: nextMonday)!

        case .nextMonth:
            let nextMonthStart = calendar.date(byAdding: .month, value: 1, to: calendar.startOfDay(for: today))!
            startDate = nextMonthStart
            endDate = calendar.date(byAdding: .day, value: 6, to: nextMonthStart)!

        case .custom:
            break
        }
    }

    private func presetDatePreview(_ preset: DatePreset) -> String {
        let calendar = Calendar.current
        let today = Date()
        switch preset {
        case .thisWeekend:
            var nextSat = today
            while calendar.component(.weekday, from: nextSat) != 7 {
                nextSat = calendar.date(byAdding: .day, value: 1, to: nextSat)!
            }
            return "\(nextSat.formatted(.dateTime.month().day())) - \(calendar.date(byAdding: .day, value: 1, to: nextSat)!.formatted(.dateTime.day().month()))"
        case .nextWeek:
            let nextMonday = calendar.date(byAdding: .weekOfYear, value: 1, to: calendar.startOfDay(for: today))!
            return "\(nextMonday.formatted(.dateTime.month().day())) - \(calendar.date(byAdding: .day, value: 4, to: nextMonday)!.formatted(.dateTime.day().month()))"
        case .nextMonth:
            let nextMonthStart = calendar.date(byAdding: .month, value: 1, to: calendar.startOfDay(for: today))!
            return "\(nextMonthStart.formatted(.dateTime.month().day())) - \(calendar.date(byAdding: .day, value: 6, to: nextMonthStart)!.formatted(.dateTime.day().month()))"
        case .custom:
            return ""
        }
    }
}
