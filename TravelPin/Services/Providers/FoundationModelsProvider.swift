import Foundation

// Apple FoundationModels provider — stub until iOS 26 SDK is available.
// When building with iOS 26+ SDK, replace this file with the real implementation
// using SystemLanguageModel / LanguageModelSession.

final class FoundationModelsProvider: AIProvider {
    let displayName = "Apple 本地模型"

    var isAvailable: Bool {
        get async {
            if #available(iOS 26, *) {
                // TODO: return SystemLanguageModel.default.availability == .available
                return false
            }
            return false
        }
    }

    func generate(prompt: String) async throws -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { $0.finish(throwing: AIProviderError.unavailable) }
    }
}
