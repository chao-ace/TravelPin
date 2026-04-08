import SwiftUI

struct CursorOverlayView: View {
    @ObservedObject var realtime = RealtimeManager.shared

    var body: some View {
        ZStack {
            ForEach(Array(realtime.onlineUsers.keys), id: \.self) { userId in
                CursorView(name: realtime.onlineUsers[userId] ?? "U")
                    .transition(.opacity)
            }
        }
    }
}

struct CursorView: View {
    let name: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: "cursorarrow.fill")
                .font(.caption)
                .foregroundStyle(Color.tpAccent)

            Text(name)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.tpAccent)
                .foregroundStyle(.white)
                .clipShape(Capsule())
        }
    }
}
