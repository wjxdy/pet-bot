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
                // 排除隐藏目录和非目录项
                guard !agentId.hasPrefix(".") else { continue }
                
                // 只读取有 config.yaml 的 agent
                if let agent = loadAgentConfig(from: item, agentId: agentId) {
                    agents.append(agent)
                }
                // 没有 config.yaml 的跳过
            }
        }
        
        // 按名称排序
        agents.sort { $0.name < $1.name }
        
        // 如果没有找到任何 agent，使用默认列表
        if agents.isEmpty {
            agents = [
                .default,
                Agent(id: "shennong", name: "神农", description: "AI 功能实验师", colorHex: "#FF6B35", icon: "🌿"),
                Agent(id: "main", name: "主助手", description: "通用 AI 助手", colorHex: "#007AFF", icon: "🤖")
            ]
        }
        
        return agents
    }
    
    private static func loadAgentConfig(from path: URL, agentId: String) -> Agent? {
        let configPath = path.appendingPathComponent("config.yaml")
        
        guard FileManager.default.fileExists(atPath: configPath.path),
              let content = try? String(contentsOf: configPath, encoding: .utf8) else {
            return nil
        }
        
        // 简单解析 YAML
        let name = parseYamlValue(content, key: "name") ?? agentId.capitalized
        let description = parseYamlValue(content, key: "description") ?? "OpenClaw Agent"
        let colorHex = parseYamlValue(content, key: "color") ?? "#007AFF"
        let icon = parseYamlValue(content, key: "icon") ?? "🤖"
        
        return Agent(
            id: agentId,
            name: name,
            description: description,
            colorHex: colorHex,
            icon: icon
        )
    }
    
    private static func parseYamlValue(_ content: String, key: String) -> String? {
        let pattern = "^\\s*" + key + "\\s*:\\s*(.+)$"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines, .caseInsensitive]) else {
            return nil
        }
        
        let range = NSRange(content.startIndex..., in: content)
        if let match = regex.firstMatch(in: content, options: [], range: range),
           let valueRange = Range(match.range(at: 1), in: content) {
            return String(content[valueRange]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return nil
    }
    
    private static func createDefaultAgent(id: String) -> Agent {
        // 预定义一些常用 agent 的信息
        let defaults: [String: (name: String, desc: String, icon: String, color: String)] = [
            "search": ("小米鼠", "擅长信息检索", "🐭", "#FF9500"),
            "shennong": ("神农", "AI 功能实验师", "🌿", "#FF6B35"),
            "main": ("主助手", "通用 AI 助手", "🤖", "#007AFF"),
            "codex": ("Codex", "编程助手", "💻", "#34C759"),
            "dijkstra": ("Dijkstra", "算法专家", "📊", "#5856D6"),
            "english-teacher": ("英语老师", "语言学习助手", "📚", "#FF2D55"),
            "napoleon": ("拿破仑", "战略顾问", "⚔️", "#AF52DE"),
            "super-helper": ("超级助手", "全能助手", "⭐", "#FFCC00")
        ]
        
        if let info = defaults[id] {
            return Agent(id: id, name: info.name, description: info.desc, colorHex: info.color, icon: info.icon)
        }
        
        return Agent(
            id: id,
            name: id.capitalized,
            description: "OpenClaw Agent",
            colorHex: "#007AFF",
            icon: "🤖"
        )
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