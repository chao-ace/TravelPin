import SwiftUI

extension View {
    func filmGrain(intensity: Float = 0.05) -> some View {
        self.modifier(FilmGrainModifier(intensity: intensity))
    }
    
    func warmFilm(warmth: Float = 0.15) -> some View {
        self.modifier(WarmFilmModifier(warmth: warmth))
    }
    
    // Focus Pull transition logic: Blur + Scale + Fade
    func focusPullTransition() -> some View {
        self.transition(.asymmetric(
            insertion: .modifier(
                active: FocusPullModifier(blur: 20, scale: 0.9, opacity: 0),
                identity: FocusPullModifier(blur: 0, scale: 1.0, opacity: 1)
            ),
            removal: .modifier(
                active: FocusPullModifier(blur: 20, scale: 1.1, opacity: 0),
                identity: FocusPullModifier(blur: 0, scale: 1.0, opacity: 1)
            )
        ))
    }
}

struct FocusPullModifier: ViewModifier {
    let blur: CGFloat
    let scale: CGFloat
    let opacity: Double
    
    func body(content: Content) -> some View {
        content
            .blur(radius: blur)
            .scaleEffect(scale)
            .opacity(opacity)
    }
}

struct FilmGrainModifier: ViewModifier {
    let intensity: Float
    let startDate = Date()
    
    func body(content: Content) -> some View {
        TimelineView(.animation) { context in
            let time = Float(context.date.timeIntervalSince(startDate))
            
            content
                .colorEffect(
                    ShaderLibrary.filmGrain(
                        .float(time),
                        .float(intensity)
                    )
                )
        }
    }
}

struct WarmFilmModifier: ViewModifier {
    let warmth: Float
    
    func body(content: Content) -> some View {
        content
            .colorEffect(
                ShaderLibrary.warmFilm(
                    .float(warmth)
                )
            )
    }
}
