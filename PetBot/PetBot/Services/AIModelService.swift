// AIModelService.swift
// AI 模型服务 - 直接对接大模型 API

import Foundation

enum AIModelProvider: String, CaseIterable {
    case openai = "OpenAI"
    case anthropic = "Anthropic"
    case openclaw = "OpenClaw Gateway"
    
    var defaultModel: String {
        switch self {
        case .openai:
            return "gpt-4"
        case .anthropic:
            return "claude-3-opus-20240229"
        case .openclaw:
            return "shennong"
        }
    }
}

struct AIModelConfig: Codable {
    var provider: String
    var model: String
    var apiKey: String
    var baseURL: String?
    var temperature: Double
    var maxTokens: Int
}

actor AIModelService {
    static let shared = AIModelService()
    
    private var config: AIModelConfig?
    private let session: URLSession
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 300
        self.session = URLSession(configuration: config)
        
        // 加载配置
        Task {
            await loadConfig()
        }
    }
    
    // MARK: - Configuration
    
    func loadConfig() {
        if let data = UserDefaults.standard.data(forKey: "aiModelConfig"),
           let config = try? JSONDecoder().decode(AIModelConfig.self, from: data) {
            self.config = config
        } else {
            // 尝试从 OpenClaw 配置读取
            loadFromOpenClawConfig()
        }
    }
    
    func saveConfig(_ config: AIModelConfig) {
        self.config = config
        if let data = try? JSONEncoder().encode(config) {
            UserDefaults.standard.set(data, forKey: "aiModelConfig")
        }
    }
    
    private func loadFromOpenClawConfig() {
        let openclawPath = AppConfiguration.openclawPath
        let configFile = URL(fileURLWithPath: openclawPath)
            .appendingPathComponent("config.json")
        
        guard let data = try? Data(contentsOf: configFile),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }
        
        // 尝试解析 OpenClaw 配置
        // 这里根据实际配置结构调整
        if let model = json["defaultModel"] as? String {
            config = AIModelConfig(
                provider: "openclaw",
                model: model,
                apiKey: "",
                baseURL: nil,
                temperature: 0.7,
                maxTokens: 2000
            )
        }
    }
    
    // MARK: - Send Message
    
    func sendMessage(_ message: String) async throws -> String {
        guard let config = config else {
            throw NSError(domain: "AIModelService", code: -1, userInfo: [NSLocalizedDescriptionKey: "未配置 AI 模型"])
        }
        
        switch config.provider {
        case "openai":
            return try await sendToOpenAI(message: message, config: config)
        case "anthropic":
            return try await sendToAnthropic(message: message, config: config)
        default:
            // 回退到 OpenClaw CLI
            return try await sendToOpenClaw(message: message)
        }
    }
    
    private func sendToOpenAI(message: String, config: AIModelConfig) async throws -> String {
        let url = URL(string: config.baseURL ?? "https://api.openai.com/v1/chat/completions")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = [
            "model": config.model,
            "messages": [
                ["role": "system", "content": "你是一个有用的助手。"],
                ["role": "user", "content": message]
            ],
            "temperature": config.temperature,
            "max_tokens": config.maxTokens
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "AIModelService", code: -1, userInfo: [NSLocalizedDescriptionKey: "API 请求失败"])
        }
        
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let choices = json["choices"] as? [[String: Any]],
           let first = choices.first,
           let message = first["message"] as? [String: Any],
           let content = message["content"] as? String {
            return content
        }
        
        throw NSError(domain: "AIModelService", code: -1, userInfo: [NSLocalizedDescriptionKey: "解析响应失败"])
    }
    
    private func sendToAnthropic(message: String, config: AIModelConfig) async throws -> String {
        let url = URL(string: config.baseURL ?? "https://api.anthropic.com/v1/messages")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(config.apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        
        let body: [String: Any] = [
            "model": config.model,
            "max_tokens": config.maxTokens,
            "messages": [
                ["role": "user", "content": message]
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "AIModelService", code: -1, userInfo: [NSLocalizedDescriptionKey: "API 请求失败"])
        }
        
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let content = json["content"] as? [[String: Any]],
           let first = content.first,
           let text = first["text"] as? String {
            return text
        }
        
        throw NSError(domain: "AIModelService", code: -1, userInfo: [NSLocalizedDescriptionKey: "解析响应失败"])
    }
    
    private func sendToOpenClaw(message: String) async throws -> String {
        // 使用现有的 OpenClaw API 服务
        return try await OpenClawAPIService.shared.sendMessage(message, agentId: AppConfiguration.selectedAgentId)
    }
}
