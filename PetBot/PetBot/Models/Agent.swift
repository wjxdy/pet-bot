// Agent.swift
// Agent 模型定义

import SwiftUI

struct Agent: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let colorHex: String
    let endpoint: String
    let icon: String
    
    var color: Color {
        Color(hex: colorHex) ?? .blue
    }
}

// Agent 管理器
class AgentManager: ObservableObject {
    @Published var currentAgent: Agent
    @Published var availableAgents: [Agent] = []
    @Published var currentResponse: String?
    @Published var isLoading = false
    @Published var lastError: String?
    
    private let openClawClient: OpenClawClient
    
    init() {
        // 默认 Agent 配置
        self.currentAgent = Agent(
            id: "shennong",
            name: "神农",
            description: "AI 功能实验师，冷静严谨",
            colorHex: "#FF6B35",
            endpoint: "ws://127.0.0.1:18789",
            icon: "flask.fill"
        )
        
        self.openClawClient = OpenClawClient()
        loadAvailableAgents()
    }
    
    func loadAvailableAgents() {
        // 预设的 Agent 列表
        availableAgents = [
            Agent(
                id: "shennong",
                name: "神农",
                description: "AI 功能实验师",
                colorHex: "#FF6B35",
                endpoint: "ws://127.0.0.1:18789",
                icon: "flask.fill"
            ),
            Agent(
                id: "main",
                name: "主助手",
                description: "通用 AI 助手",
                colorHex: "#007AFF",
                endpoint: "ws://127.0.0.1:18789",
                icon: "bubble.left.fill"
            ),
            Agent(
                id: "search",
                name: "搜索专家",
                description: "擅长信息检索",
                colorHex: "#34C759",
                endpoint: "ws://127.0.0.1:18789",
                icon: "magnifyingglass.circle.fill"
            ),
            Agent(
                id: "claude",
                name: "Claude",
                description: "Anthropic Claude",
                colorHex: "#8E44AD",
                endpoint: "ws://127.0.0.1:18789",
                icon: "brain.fill"
            )
        ]
    }
    
    func switchToAgent(_ agentId: String) {
        if let agent = availableAgents.first(where: { $0.id == agentId }) {
            withAnimation {
                currentAgent = agent
                currentResponse = nil
                lastError = nil
            }
        }
    }
    
    func sendMessage(_ message: String) async {
        await MainActor.run {
            isLoading = true
            lastError = nil
        }
        
        do {
            let response = try await openClawClient.sendMessage(
                message: message,
                agentId: currentAgent.id,
                endpoint: currentAgent.endpoint
            )
            
            await MainActor.run {
                currentResponse = response
                isLoading = false
            }
        } catch {
            await MainActor.run {
                lastError = error.localizedDescription
                isLoading = false
            }
        }
    }
}

// 颜色扩展
extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
