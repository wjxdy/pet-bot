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
        // OpenClaw Gateway API
        guard let url = URL(string: "http://127.0.0.1:18789/agent") else {
            throw OpenClawError.invalidURL
        }
        
        // 构建请求体 - OpenClaw agent 格式
        let requestBody: [String: Any] = [
            "message": message,
            "agent": agentId  // 使用 agent id，如 "shennong"
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
        
        // 调试输出
        if let responseString = String(data: data, encoding: .utf8) {
            print("OpenClaw Response: \(responseString)")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw OpenClawError.serverError(statusCode: httpResponse.statusCode, message: errorText)
        }
        
        // 解析响应
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            // 尝试不同的响应格式
            if let content = json["response"] as? String {
                return content
            } else if let content = json["message"] as? String {
                return content
            } else if let content = json["content"] as? String {
                return content
            } else if let text = json["text"] as? String {
                return text
            }
        }
        
        // 返回原始文本
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
