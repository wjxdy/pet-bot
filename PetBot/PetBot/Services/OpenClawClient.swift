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
        // 模拟响应（用于测试气泡显示）
        // 实际使用时，这里应该连接真实的 OpenClaw Gateway
        
        // 延迟一下模拟网络请求
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
        
        // 返回模拟响应
        return "收到消息：\(message)\n\n我是 \(agentId)，正在测试中..."
        
        /* 实际 API 调用代码（暂时注释）
        guard let url = URL(string: "http://127.0.0.1:18789/api/v1/chat") else {
            throw OpenClawError.invalidURL
        }
        ...
        */
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
