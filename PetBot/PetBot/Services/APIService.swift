// APIService.swift
// API 服务层 - 统一的网络请求管理

import Foundation

protocol APIServiceProtocol {
    func sendMessage(_ message: String, agentId: String) async throws -> String
}

enum APIError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case serverError(Int, String)
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的 URL"
        case .networkError(let error):
            return "网络错误: \(error.localizedDescription)"
        case .invalidResponse:
            return "无效的响应"
        case .serverError(let code, let message):
            return "服务器错误 (\(code)): \(message)"
        case .decodingError:
            return "解析响应失败"
        }
    }
}

actor OpenClawAPIService: APIServiceProtocol {
    static let shared = OpenClawAPIService()
    
    private let session: URLSession
    private let baseURL: String
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 300
        self.session = URLSession(configuration: config)
        self.baseURL = AppConfiguration.gatewayURL
    }
    
    func sendMessage(_ message: String, agentId: String) async throws -> String {
        // 尝试调用 OpenClaw agent
        do {
            return try await callOpenClawAgent(message: message, agentId: agentId)
        } catch {
            AppLogger.error("OpenClaw 调用失败: \(error.localizedDescription)")
            // 失败时返回模拟响应
            return "[模拟] 收到: \(message)\n\n(OpenClaw 连接失败，使用模拟响应)"
        }
    }
    
    private func callOpenClawAgent(message: String, agentId: String) async throws -> String {
        // 使用 OpenClaw sessions_send 工具内部 API
        // 由于 HTTP API 可能不可用，这里使用简单的模拟
        // 实际使用时需要配置正确的 OpenClaw agent HTTP 端点
        
        throw APIError.invalidURL
    }
    
    private func parseResponse(_ data: Data) throws -> String {
        // 尝试解析 JSON
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            let possibleKeys = ["response", "message", "content", "text", "result"]
            for key in possibleKeys {
                if let content = json[key] as? String {
                    return content
                }
            }
        }
        
        // 返回原始文本
        if let text = String(data: data, encoding: .utf8) {
            return text
        }
        
        throw APIError.decodingError
    }
}

// MARK: - Request/Response Models
struct OpenClawRequest: Codable {
    let message: String
    let agent: String
}

struct OpenClawResponse: Codable {
    let response: String?
    let message: String?
    let content: String?
    let error: String?
}
