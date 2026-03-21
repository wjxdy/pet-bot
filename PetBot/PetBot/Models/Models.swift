// Models.swift
// 数据模型定义

import SwiftUI

// MARK: - Agent Model
struct Agent: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let description: String
    let colorHex: String
    let icon: String
    
    var color: Color {
        Color(hex: colorHex) ?? .blue
    }
}

// MARK: - Default Agents
extension Agent {
    static let `default` = Agent(
        id: "search",
        name: "小米鼠",
        description: "擅长信息检索",
        colorHex: "#FF9500",
        icon: "🐭"
    )
    
    static let all: [Agent] = loadAgentsFromConfig()
    
    // 从本地 .openclaw 配置读取 agent 列表
    private static func loadAgentsFromConfig() -> [Agent] {
        let configPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".openclaw/agents/shennong/workspace/AGENTS.md")
        
        // 如果配置文件存在，尝试读取
        if FileManager.default.fileExists(atPath: configPath.path) {
            // 这里可以添加解析逻辑
            // 暂时返回默认列表
        }
        
        // 扫描 .openclaw/agents 目录
        let agentsDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".openclaw/agents")
        
        var agents: [Agent] = []
        
        if let contents = try? FileManager.default.contentsOfDirectory(
            at: agentsDir,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        ) {
            for item in contents {
                let agentId = item.lastPathComponent
                // 排除非 agent 目录
                if !agentId.hasPrefix(".") && agentId != "shennong" {
                    agents.append(Agent(
                        id: agentId,
                        name: agentId.capitalized,
                        description: "OpenClaw Agent",
                        colorHex: "#007AFF",
                        icon: "🤖"
                    ))
                }
            }
        }
        
        // 确保至少有默认 agent
        if agents.isEmpty {
            agents = [
                .default,
                Agent(id: "shennong", name: "神农", description: "AI 功能实验师", colorHex: "#FF6B35", icon: "🌿"),
                Agent(id: "main", name: "主助手", description: "通用 AI 助手", colorHex: "#007AFF", icon: "🤖"),
                Agent(id: "claude", name: "Claude", description: "Anthropic Claude", colorHex: "#8E44AD", icon: "🧠")
            ]
        }
        
        return agents
    }
}

// MARK: - Color Extension
extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
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
