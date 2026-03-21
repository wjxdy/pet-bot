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
        // 使用 OpenClaw HTTP API 调用 agent
        let endpoint = "\(baseURL)/v1/chat"
        
        guard let url = URL(string: endpoint) else {
            throw APIError.invalidURL
        }
        
        // OpenClaw API 格式
        let requestBody: [String: Any] = [
            "message": message,
            "agent_id": agentId,
            "session_id": "petbot-\(UUID().uuidString.prefix(8))"
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        AppLogger.info("发送请求到: \(endpoint), agent: \(agentId)")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        AppLogger.info("收到响应: HTTP \(httpResponse.statusCode)")
        
        if let responseString = String(data: data, encoding: .utf8) {
            AppLogger.info("响应内容: \(responseString.prefix(200))...")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.serverError(httpResponse.statusCode, errorText)
        }
        
        return try parseResponse(data)
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
