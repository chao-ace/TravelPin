import SwiftUI

struct CinematicTextField: View {
    let placeholderLocKey: String
    @Binding var text: String
    var icon: String? = nil
    var axis: Axis = .horizontal
    var lineLimit: ClosedRange<Int>? = nil
    var isLoading: Bool = false
    var trailingIcon: String? = nil

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(isFocused ? Color.tpAccent : TPDesign.textTertiary)
                        .frame(width: 20)
                }

                TextField(placeholderLocKey.localized, text: $text, axis: axis)
                    .font(TPDesign.bodyFont())
                    .foregroundStyle(TPDesign.textPrimary)
                    .lineLimit(lineLimit ?? (axis == .vertical ? 3...10 : 1...1))
                    .focused($isFocused)
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(Color.tpAccent)
                } else if let trailingIcon {
                    Image(systemName: trailingIcon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.tpAccent)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            // Animated underline
            Rectangle()
                .fill(isFocused ? Color.tpAccent : TPDesign.divider)
                .frame(height: isFocused ? 2 : 1)
                .animation(.easeInOut(duration: 0.25), value: isFocused)
        }
    }
}
