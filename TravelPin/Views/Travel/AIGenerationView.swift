import SwiftUI

struct AIGenerationView: View {
    let travel: Travel
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedStyle: AIAssistantService.WritingStyle = .poetic
    @State private var generatedText = ""
    @State private var isGenerating = false
    
    var body: some View {
        NavigationStack {
            VStack {
                if generatedText.isEmpty {
                    initialView
                } else {
                    resultView
                }
            }
            .navigationTitle("ai.review.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("common.close".localized) { dismiss() }
                }
            }
        }
    }
    
    private var initialView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "wand.and.stars")
                .font(.system(size: 80))
                .foregroundStyle(Color.tpAccent)
            
            VStack(spacing: 12) {
                Text(locKey: "ai.review.header")
                    .font(TPDesign.titleFont(24))
                Text(locKey: "ai.review.subtitle")
                    .font(TPDesign.bodyFont())
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 40)
            }
            
            Picker("ai.review.style".localized, selection: $selectedStyle) {
                ForEach(AIAssistantService.WritingStyle.allCases, id: \.self) { style in
                    Text(style.rawValue).tag(style)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 120)
            
            CinematicPrimaryButton(
                locKey: "ai.review.generate",
                icon: "sparkles",
                isLoading: isGenerating
            ) {
                generateAction()
            }
            .padding(.horizontal, 30)
            
            Spacer()
        }
    }
    
    private var resultView: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 30) {
                // Journal Header Decor
                Rectangle()
                    .fill(Color.tpAccent.opacity(0.1))
                    .frame(height: 1)
                    .overlay(
                        Text(locKey: "ai.review.memoir")
                            .font(.caption2).tracking(4)
                            .padding(.horizontal, 10)
                            .background(Color.white)
                    )
                    .padding(.top, 20)
                
                VStack(alignment: .leading, spacing: 20) {
                    Text(generatedText)
                        .font(.custom("Palatino", size: 18)) // Literary feel
                        .lineSpacing(10)
                        .foregroundStyle(TPDesign.obsidian.opacity(0.85))
                }
                .padding(32)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.white.opacity(0.6))
                        .background(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(.white.opacity(0.4), lineWidth: 1)
                        )
                )
                .shadowLarge()
                
                HStack(spacing: 16) {
                    Button(action: {
                        let pasteboard = UIPasteboard.general
                        pasteboard.string = generatedText
                        TPHaptic.notification(.success)
                    }) {
                        Label("ai.review.copy".localized, systemImage: "doc.on.doc")
                            .font(TPDesign.bodyFont(15, weight: .bold))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Capsule().fill(.ultraThinMaterial))
                            .overlay(Capsule().stroke(TPDesign.divider, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    
                    ShareLink(item: generatedText) {
                        Label("ai.review.share".localized, systemImage: "square.and.arrow.up")
                            .font(TPDesign.bodyFont(15, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(TPDesign.accentGradient)
                            .clipShape(Capsule())
                    }
                }
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 20)
        }
    }
    
    private func generateAction() {
        isGenerating = true
        Task {
            do {
                generatedText = try await AIAssistantService.shared.generateJournalComplete(for: travel, style: selectedStyle)
            } catch {
                generatedText = "生成失败：\(error.localizedDescription)"
            }
            isGenerating = false
        }
    }
}
