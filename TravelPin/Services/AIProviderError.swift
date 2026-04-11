import Foundation

enum AIProviderError: LocalizedError {
    case unavailable
    case invalidResponse
    case noAPIKey
    case networkError(String)
    case generationFailed(String)
    case usageLimitExceeded

    var errorDescription: String? {
        switch self {
        case .unavailable:
            return "当前设备不支持此 AI 模型"
        case .invalidResponse:
            return "AI 服务返回了无效响应"
        case .noAPIKey:
            return "请先在设置中配置 API Key"
        case .networkError(let detail):
            return "网络错误：\(detail)"
        case .generationFailed(let detail):
            return "生成失败：\(detail)"
        case .usageLimitExceeded:
            return "免费使用次数已用完，请订阅 TravelPin AI 以继续使用"
        }
    }
}
