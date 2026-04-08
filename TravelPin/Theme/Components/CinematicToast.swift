import SwiftUI
import Combine

enum ToastType {
    case info, success, warning, error
    
    var icon: String {
        switch self {
        case .info: return "info.circle"
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.octagon.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .info: return .blue
        case .success: return .green
        case .warning: return .orange
        case .error: return .red
        }
    }
}

struct Toast: Identifiable {
    let id = UUID()
    let type: ToastType
    let message: String
    var duration: Double = 3.0
}

class ToastManager: ObservableObject {
    static let shared = ToastManager()
    
    @Published var toast: Toast? = nil
    private var cancellable: AnyCancellable?
    
    private init() {}
    
    func show(type: ToastType, message: String, duration: Double = 3.0) {
        // Run on main thread
        DispatchQueue.main.async {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                self.toast = Toast(type: type, message: message, duration: duration)
            }
            
            // Auto hide
            self.cancellable?.cancel()
            self.cancellable = Just(true)
                .delay(for: .seconds(duration), scheduler: RunLoop.main)
                .sink { [weak self] _ in
                    self?.hide()
                }
        }
    }
    
    func hide() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            self.toast = nil
        }
    }
}

struct CinematicToast: View {
    let toast: Toast
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: toast.type.icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(toast.type.color)
            
            Text(toast.message)
                .font(TPDesign.bodyFont(14))
                .foregroundStyle(TPDesign.textPrimary)
            
            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background {
            Capsule()
                .fill(TPDesign.secondaryBackground)
                .shadowMedium()
        }
        .overlay(
            Capsule()
                .stroke(TPDesign.divider, lineWidth: 0.5)
        )
        .padding(.horizontal, 24)
    }
}

struct ToastModifier: ViewModifier {
    @ObservedObject var toastManager = ToastManager.shared
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            VStack {
                if let toast = toastManager.toast {
                    CinematicToast(toast: toast)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .onTapGesture {
                            toastManager.hide()
                        }
                    Spacer()
                }
            }
            .padding(.top, 60) // Safe area and distance from top
            .zIndex(100)
        }
    }
}

extension View {
    func withToast() -> some View {
        self.modifier(ToastModifier())
    }
}
