import SwiftUI

struct CinematicSegmentedPicker<T: Hashable>: View {
    let options: [T]
    @Binding var selection: T
    let labelFor: (T) -> String
    var accentColor: Color = .tpAccent

    @Namespace private var animation

    var body: some View {
        HStack(spacing: 4) {
            ForEach(options, id: \.self) { option in
                let isSelected = selection == option
                Button {
                    withAnimation(TPDesign.springDefault) {
                        selection = option
                    }
                } label: {
                    Text(labelFor(option))
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(isSelected ? .white : TPDesign.textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(minWidth: 0)
                        .background {
                            if isSelected {
                                Capsule()
                                    .fill(TPDesign.accentGradient)
                                    .matchedGeometryEffect(id: "picker_indicator", in: animation)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color.tpSurface)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(TPDesign.divider, lineWidth: 1)
        )
    }
}
