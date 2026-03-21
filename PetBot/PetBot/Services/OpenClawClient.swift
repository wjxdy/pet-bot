// OpenClawClient.swift
// OpenClaw 通信客户端

import Foundation

class OpenClawClient {
    private var session: URLSession
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 300
        self.session = URLSession(configuration: config)
    }
    
    func sendMessage(message: String, agentId: String, endpoint: String) async throws -> String {
        // OpenClaw Gateway HTTP API
        guard let url = URL(string: "http://127.0.0.1:18789/api/v1/chat") else {
            throw OpenClawError.invalidURL
        }
        
        // 构建请求体 - 使用 OpenClaw 格式
        let requestBody: [String: Any] = [
            "message": message,
            "agent_id": agentId,
            "channel": "direct",
            "stream": false
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        // 发送请求
        let (data, response) = try await session.data(for: request)
        
        // 检查响应
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenClawError.invalidResponse
        }
        
        // 打印调试信息
        if let responseString = String(data: data, encoding: .utf8) {
            print("OpenClaw Response: \(responseString)")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw OpenClawError.serverError(statusCode: httpResponse.statusCode, message: errorText)
        }
        
        // 尝试解析不同格式的响应
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            // 尝试从 response 或 message 或 content 字段获取
            if let content = json["response"] as? String {
                return content
            } else if let content = json["message"] as? String {
                return content
            } else if let content = json["content"] as? String {
                return content
            } else if let choices = json["choices"] as? [[String: Any]],
                      let first = choices.first,
                      let content = first["content"] as? String {
                return content
            }
        }
        
        // 如果无法解析，返回原始文本
        return String(data: data, encoding: .utf8) ?? "无法解析响应"
    }
}

// 错误类型
enum OpenClawError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(statusCode: Int, message: String)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的 URL"
        case .invalidResponse:
            return "无效的响应"
        case .serverError(let code, let message):
            return "服务器错误 (\(code)): \(message)"
        case .networkError(let error):
            return "网络错误: \(error.localizedDescription)"
        }
    }
}
