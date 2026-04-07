import SwiftUI
import SwiftData

struct AddItineraryView: View {
    let travel: Travel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var day: Int
    @State private var origin = ""
    @State private var destination = ""

    init(travel: Travel, initialDay: Int = 1) {
        self.travel = travel
        _day = State(initialValue: initialDay)
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: TPDesign.spacing32) {
                    // MARK: - Day Selector
                    VStack(spacing: TPDesign.spacing8) {
                        Text("设定天数")
                            .font(TPDesign.overline())
                            .foregroundStyle(TPDesign.textTertiary)
                            .tracking(2)

                        HStack(spacing: TPDesign.spacing24) {
                            // Decrease Button
                            Button {
                                withAnimation(TPDesign.springBouncy) {
                                    if day > 1 { 
                                        day -= 1 
                                        TPHaptic.selection()
                                    }
                                }
                            } label: {
                                Image(systemName: "minus.circle")
                                    .font(.system(size: 28, weight: .medium))
                                    .foregroundStyle(day > 1 ? Color.tpAccent : TPDesign.textTertiary)
                            }
                            .disabled(day <= 1)

                            // Day Number
                            Text("\(day)")
                                .font(TPDesign.cinematicTitle(48))
                                .foregroundStyle(TPDesign.textPrimary)
                                .frame(minWidth: 80)
                                .contentTransition(.numericText())
                                .animation(TPDesign.springBouncy, value: day)

                            Text("天")
                                .font(TPDesign.titleFont(20))
                                .foregroundStyle(TPDesign.textTertiary)

                            // Increase Button
                            Button {
                                withAnimation(TPDesign.springBouncy) {
                                    if day < 31 { 
                                        day += 1 
                                        TPHaptic.selection()
                                    }
                                }
                            } label: {
                                Image(systemName: "plus.circle")
                                    .font(.system(size: 28, weight: .medium))
                                    .foregroundStyle(day < 31 ? Color.tpAccent : TPDesign.textTertiary)
                            }
                            .disabled(day >= 31)
                        }
                    }
                    .padding(.vertical, TPDesign.spacing16)
                    .cinematicFadeIn(delay: 0)

                    // MARK: - Route Section
                    CinematicFormSection(title: "行程路线") {
                        HStack(spacing: TPDesign.spacing12) {
                            // Origin
                            CinematicTextField(
                                placeholder: "从哪出发",
                                text: $origin,
                                icon: "location.fill"
                            )

                            // Arrow Decoration
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(Color.tpAccent)

                            // Destination
                            CinematicTextField(
                                placeholder: "要去哪里",
                                text: $destination,
                                icon: "mappin.and.ellipse"
                            )
                        }
                    }
                    .cinematicFadeIn(delay: 0.15)

                    // MARK: - Action Buttons
                    VStack(spacing: TPDesign.spacing12) {
                        Button {
                            save()
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "plus")
                                Text("确认添加")
                            }
                            .font(TPDesign.bodyFont(16).weight(.bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(TPDesign.brandGradient)
                            .clipShape(Capsule())
                            .shadowSmall()
                        }
                        .disabled(origin.isEmpty || destination.isEmpty)

                        Button {
                            dismiss()
                        } label: {
                            Text("取消")
                                .font(TPDesign.bodyFont(16))
                                .foregroundStyle(TPDesign.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                        }
                    }
                    .padding(.top, TPDesign.spacing8)
                    .padding(.bottom, TPDesign.spacing32)
                    .cinematicFadeIn(delay: 0.3)
                }
                .padding(.horizontal, TPDesign.spacing20)
                .padding(.top, TPDesign.spacing24)
            }
            .background(TPDesign.backgroundGradient)
            .navigationTitle("添加行程")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        save()
                        dismiss()
                    }
                    .disabled(origin.isEmpty || destination.isEmpty)
                }
            }
        }
    }
}

extension AddItineraryView {
    @ViewBuilder
    private func CinematicFormSection<Content: View>(title: String, @ViewBuilder content: @escaping () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(TPDesign.overline())
                .foregroundStyle(TPDesign.textTertiary)
                .tracking(2)
                .padding(.horizontal, 4)

            content()
                .padding(16)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(.white.opacity(0.3), lineWidth: 0.5)
                )
        }
    }

    @ViewBuilder
    private func CinematicTextField(placeholder: String, text: Binding<String>, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color.tpAccent)
                .font(.system(size: 14))
            
            TextField(placeholder, text: text)
                .font(TPDesign.bodyFont(16))
        }
    }

    private func save() {
        let newItinerary = Itinerary(day: day, origin: origin, destination: destination)
        newItinerary.travel = travel
        modelContext.insert(newItinerary)
        try? modelContext.save() // Force immediate write for reactive UI
        TPHaptic.notification(.success)
    }
}
