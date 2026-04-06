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
            
            Button(action: generateAction) {
                if isGenerating {
                    ProgressView()
                } else {
                    Text(locKey: "ai.review.generate")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.tpAccent)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding(.horizontal, 30)
            .disabled(isGenerating)
            
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
                        .foregroundStyle(.primary.opacity(0.8))
                }
                .padding(30)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.quaternary, lineWidth: 0.5)
                        .background(.white)
                )
                
                HStack(spacing: 16) {
                    Button(action: {
                        let pasteboard = UIPasteboard.general
                        pasteboard.string = generatedText
                    }) {
                        Label("ai.review.copy".localized, systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.bordered)
                    
                    ShareLink(item: generatedText) {
                        Label("ai.review.share".localized, systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.tpAccent)
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
