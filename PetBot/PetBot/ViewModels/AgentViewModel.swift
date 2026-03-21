// AgentViewModel.swift
// Agent 业务逻辑层

import SwiftUI
import Combine

@MainActor
class AgentViewModel: ObservableObject {
    // MARK: - Shared Instance
    static let shared = AgentViewModel()
    // MARK: - Published Properties
    @Published var currentAgent: Agent
    @Published var availableAgents: [Agent] = []
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Dependencies
    private let apiService: OpenClawAPIService
    
    // MARK: - Initialization
    init(apiService: OpenClawAPIService = .shared) {
        self.apiService = apiService
        self.availableAgents = Agent.all
        
        // 使用配置的 agent ID
        let savedAgentId = AppConfiguration.selectedAgentId
        if let agent = Agent.all.first(where: { $0.id == savedAgentId }) {
            self.currentAgent = agent
        } else {
            self.currentAgent = .default
        }
    }
    
    // MARK: - Public Methods
    func switchAgent(_ agent: Agent) {
        guard agent.id != currentAgent.id else { return }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            currentAgent = agent
            errorMessage = nil
        }
        
        // 保存到配置
        AppConfiguration.selectedAgentId = agent.id
        
        AppLogger.info("切换到 Agent: \(agent.name)")
    }
    
    func sendMessage(_ content: String) async {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        // 添加用户消息
        let userMessage = ChatMessage(content: trimmed, isUser: true, agentName: currentAgent.name, timestamp: Date())
        await addMessage(userMessage)
        
        // 发送给 API
        await setLoading(true)
        
        do {
            let response = try await apiService.sendMessage(trimmed, agentId: currentAgent.id)
            let botMessage = ChatMessage(content: response, isUser: false, agentName: currentAgent.name, timestamp: Date())
            await addMessage(botMessage)
            AppLogger.success("收到响应，长度: \(response.count)")
        } catch {
            await handleError(error)
        }
        
        await setLoading(false)
    }
    
    func clearMessages() {
        messages.removeAll()
    }
    
    // MARK: - Private Methods
    private func addMessage(_ message: ChatMessage) async {
        messages.append(message)
    }
    
    private func setLoading(_ loading: Bool) async {
        isLoading = loading
    }
    
    private func handleError(_ error: Error) async {
        let message: String
        if let apiError = error as? APIError {
            message = apiError.localizedDescription
        } else {
            message = error.localizedDescription
        }
        
        errorMessage = message
        AppLogger.error(message)
    }
}
