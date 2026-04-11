import Foundation
import Combine

// MARK: - AI Provider Protocol

protocol AIProvider {
    /// Display name for settings UI
    var displayName: String { get }

    /// Whether this provider is currently available (e.g., has API key, OS version supported)
    var isAvailable: Bool { get async }

    /// Generate text from a prompt, returning a stream of tokens
    func generate(prompt: String) async throws -> AsyncThrowingStream<String, Error>

    /// Generate complete text (collects all tokens from stream)
    func generateComplete(prompt: String) async throws -> String
}

// Default implementation for generateComplete
extension AIProvider {
    func generateComplete(prompt: String) async throws -> String {
        let stream = try await generate(prompt: prompt)
        var result = ""
        for try await token in stream {
            result += token
        }
        return result
    }
}

// MARK: - Provider Registry

enum AIProviderType: String, CaseIterable, Codable {
    case travelPinAI = "travelpin_ai"
    case localTemplate = "local_template"

    var displayName: String {
        switch self {
        case .travelPinAI: return "TravelPin AI"
        case .localTemplate: return "系统默认智能模板"
        }
    }
}

@MainActor
final class AIProviderRegistry: ObservableObject {
    static let shared = AIProviderRegistry()

    @Published var activeProviderType: AIProviderType {
        didSet { UserDefaults.standard.set(activeProviderType.rawValue, forKey: "ai_provider_type") }
    }

    private init() {
        let savedType = UserDefaults.standard.string(forKey: "ai_provider_type") ?? AIProviderType.travelPinAI.rawValue
        self.activeProviderType = AIProviderType(rawValue: savedType) ?? .travelPinAI
    }
}
