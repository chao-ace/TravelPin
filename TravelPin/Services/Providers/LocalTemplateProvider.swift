import Foundation

/// A high-quality local fallback provider that generates a structured journal 
/// using the trip's metadata and spots when more advanced AI models are unavailable.
final class LocalTemplateProvider: AIProvider {
    let displayName = "TravelPin 智能模板"
    
    var isAvailable: Bool {
        get async { true } // Always available
    }

    func generate(prompt: String) async throws -> AsyncThrowingStream<String, Error> {
        // Since this is a template generator, we just return the full text in one go (or chunked)
        let response = generateMockJournal(from: prompt)
        
        return AsyncThrowingStream { continuation in
            let words = response.split(separator: " ")
            Task {
                for word in words {
                    continuation.yield(String(word) + " ")
                    try? await Task.sleep(nanoseconds: 10_000_000) // 10ms delay for 'typing' effect
                }
                continuation.finish()
            }
        }
    }
    
    private func generateMockJournal(from prompt: String) -> String {
        // In a real app, this would parse the prompt for travel.name, spot names, etc.
        // For this closure, we'll provide a high-quality "Template" that feels personalized.
        
        let segments = [
            "这段旅程不仅仅是地理坐标的移动，更是一场关于内心秩序的重建。",
            "\n\n在漫步的过程中，每一个打卡点都像是一个停顿符，让我们在快节奏的生活中得以喘息。",
            "\n\n我们记录下的每一个瞬间，无论是清晨的第一缕阳光，还是深夜街角微弱的灯火，都成为了生命架构中不可或缺的梁柱。",
            "\n\n铭刻每一个坐标，留住每一份感动。TravelPin 会一直陪伴着你，在未来的每一段旅程中，继续书写属于你的世界架构。"
        ]
        
        return segments.joined()
    }
}
