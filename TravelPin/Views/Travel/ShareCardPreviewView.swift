import SwiftUI

struct ShareCardPreviewView: View {
    let travel: Travel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                TPDesign.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Travel card preview
                        ShareCardGenerator.generateTravelCard(travel: travel)
                            .shadowLarge()

                        // Share button
                        VStack(spacing: 12) {
                            ShareLink(
                                item: "探索 \(travel.name) — TravelPin",
                                subject: Text(travel.name),
                                message: Text("分享旅行卡片：\(travel.name) · \(travel.startDate.formatted(.dateTime.year().month().day())) - \(travel.endDate.formatted(.dateTime.day().month().year()))")
                            ) {
                                HStack(spacing: 10) {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("分享到社交平台")
                                        .font(TPDesign.bodyFont(16, weight: .bold))
                                }
                                .foregroundStyle(.white)
                                .padding(.vertical, 16)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: TPDesign.radiusMedium)
                                        .fill(TPDesign.accentGradient)
                                )
                            }

                            Button {
                                dismiss()
                            } label: {
                                Text("common.close".localized)
                                    .font(TPDesign.bodyFont(14))
                                    .foregroundStyle(TPDesign.textTertiary)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                    .padding(.top, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(TPDesign.textTertiary)
                    }
                }
            }
        }
    }
}
