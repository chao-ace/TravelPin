import SwiftUI
import SwiftData

// MARK: - Clipboard Import Sheet

struct ClipboardImportSheet: View {
    let travel: Travel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var importResult: ClipboardImportResult?
    @State private var selectedSpots: Set<UUID> = []
    @State private var isParsing = false

    var body: some View {
        NavigationStack {
            ZStack {
                TPDesign.background.ignoresSafeArea()

                if isParsing {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("正在解析剪贴板内容...")
                            .font(TPDesign.bodyFont(14))
                            .foregroundStyle(TPDesign.textTertiary)
                    }
                } else if let result = importResult {
                    resultView(result)
                } else {
                    emptyState
                }
            }
            .navigationTitle("import.clipboard.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("common.cancel".localized) { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if let result = importResult, !selectedSpots.isEmpty {
                        Button {
                            importSelectedSpots(result)
                        } label: {
                            Text("import.action.add".localized)
                                .fontWeight(.bold)
                        }
                    }
                }
            }
        }
        .task {
            isParsing = true
            importResult = ClipboardImportService.shared.parseClipboard()
            isParsing = false
            // Auto-select all spots
            if let result = importResult {
                selectedSpots = Set(result.suggestedSpots.map(\.id))
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(TPDesign.textTertiary)
            Text("import.empty.title".localized)
                .font(TPDesign.bodyFont(16, weight: .semibold))
                .foregroundStyle(TPDesign.textPrimary)
            Text("import.empty.subtitle".localized)
                .font(TPDesign.bodyFont(14))
                .foregroundStyle(TPDesign.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    // MARK: - Result View

    private func resultView(_ result: ClipboardImportResult) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                // Source preview
                VStack(alignment: .leading, spacing: 8) {
                    Text("import.source.preview".localized)
                        .font(TPDesign.overline())
                        .foregroundStyle(TPDesign.textTertiary)
                        .tracking(1)

                    Text(result.rawText.prefix(200))
                        .font(TPDesign.bodyFont(13))
                        .foregroundStyle(TPDesign.textSecondary)
                        .lineLimit(4)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(TPDesign.surface1)
                        )
                }

                // Detected spots
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(String(format: "import.spots.found".localized, result.suggestedSpots.count))
                            .font(TPDesign.editorialSerif(20))
                            .foregroundStyle(TPDesign.obsidian)
                        Spacer()
                        Button {
                            if selectedSpots.count == result.suggestedSpots.count {
                                selectedSpots.removeAll()
                            } else {
                                selectedSpots = Set(result.suggestedSpots.map(\.id))
                            }
                        } label: {
                            Text(selectedSpots.count == result.suggestedSpots.count ? "取消全选" : "全选")
                                .font(TPDesign.captionFont())
                                .foregroundStyle(Color.tpAccent)
                        }
                    }

                    ForEach(result.suggestedSpots) { spot in
                        importedSpotRow(spot)
                    }
                }

                // Budget hint
                if let budget = result.suggestedBudget {
                    HStack(spacing: 8) {
                        Image(systemName: "yensign.circle")
                            .foregroundStyle(TPDesign.warmGold)
                        Text("检测到预算：¥\(Int(budget))")
                            .font(TPDesign.bodyFont(14))
                            .foregroundStyle(TPDesign.textSecondary)
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(TPDesign.warmGold.opacity(0.06)))
                }
            }
            .padding(20)
        }
    }

    private func importedSpotRow(_ spot: ImportedSpot) -> some View {
        Button {
            withAnimation(TPDesign.springBouncy) {
                if selectedSpots.contains(spot.id) {
                    selectedSpots.remove(spot.id)
                } else {
                    selectedSpots.insert(spot.id)
                }
            }
        } label: {
            HStack(spacing: 12) {
                // Checkbox
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(selectedSpots.contains(spot.id) ? Color.tpAccent : TPDesign.divider, lineWidth: 2)
                        .frame(width: 24, height: 24)
                    if selectedSpots.contains(spot.id) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 24, height: 24)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color.tpAccent))
                    }
                }

                // Type icon
                Image(systemName: spot.type.icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.tpAccent)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Color.tpAccent.opacity(0.08)))

                VStack(alignment: .leading, spacing: 2) {
                    Text(spot.name)
                        .font(TPDesign.bodyFont(15, weight: .semibold))
                        .foregroundStyle(TPDesign.textPrimary)
                        .lineLimit(1)

                    if let notes = spot.notes {
                        Text(notes)
                            .font(TPDesign.bodyFont(12))
                            .foregroundStyle(TPDesign.textSecondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Source indicator
                Text(sourceLabel(spot.source))
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(TPDesign.textTertiary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(TPDesign.surface1))
            }
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func importSelectedSpots(_ result: ClipboardImportResult) {
        for spot in result.suggestedSpots where selectedSpots.contains(spot.id) {
            let newSpot = Spot(name: spot.name, type: spot.type.rawValue)
            newSpot.travel = travel
            if let notes = spot.notes {
                newSpot.notes = notes
            }
            // Assign to last itinerary if exists
            if let lastItinerary = travel.itineraries.max(by: { $0.day < $1.day }) {
                newSpot.itinerary = lastItinerary
                newSpot.sequence = travel.spots.filter { $0.itinerary?.day == lastItinerary.day }.count + 1
            }
            modelContext.insert(newSpot)
        }
        try? modelContext.save()
        TPHaptic.notification(.success)
        dismiss()
    }

    private func sourceLabel(_ source: ImportedSpot.ImportSource) -> String {
        switch source {
        case .emoji: return "Emoji"
        case .numbered: return "列表"
        case .marker: return "标记"
        case .dash: return "描述"
        }
    }
}
