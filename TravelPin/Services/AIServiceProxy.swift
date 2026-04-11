import Foundation
import Supabase

@MainActor
final class AIServiceProxy {
    static let shared = AIServiceProxy()

    private let endpoint = URL(string: "https://ywikwxamnllxsrrxvylv.supabase.co/functions/v1/ai-proxy")!

    private init() {}

    /// Send a prompt to the Supabase Edge Function proxy, which forwards to ZhipuAI GLM-5.1.
    func generateComplete(prompt: String) async throws -> String {
        let accessToken = try await getAccessToken()

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "messages": [["role": "user", "content": prompt]],
            "temperature": 0.7
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw AIProviderError.invalidResponse
        }

        if http.statusCode == 403 {
            throw AIProviderError.usageLimitExceeded
        }

        guard http.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? "unknown"
            throw AIProviderError.networkError("Server error \(http.statusCode): \(body)")
        }

        // Parse ZhipuAI response: { "choices": [{ "message": { "content": "..." } }] }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw AIProviderError.invalidResponse
        }

        return content
    }

    /// Send a system + user message pair for structured generation (itineraries, packing, etc.)
    func generateComplete(systemPrompt: String, userPrompt: String) async throws -> String {
        let accessToken = try await getAccessToken()

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userPrompt]
            ],
            "temperature": 0.7
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw AIProviderError.invalidResponse
        }

        if http.statusCode == 403 {
            throw AIProviderError.usageLimitExceeded
        }

        guard http.statusCode == 200 else {
            throw AIProviderError.networkError("Server error \(http.statusCode)")
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw AIProviderError.invalidResponse
        }

        return content
    }

    private func getAccessToken() async throws -> String {
        let session = try await SupabaseService.shared.client.auth.session
        return session.accessToken
    }
}
