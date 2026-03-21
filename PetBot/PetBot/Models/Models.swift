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
    
    static let all: [Agent] = [
        .default,
        Agent(
            id: "shennong",
            name: "神农",
            description: "AI 功能实验师",
            colorHex: "#FF6B35",
            icon: "🌿"
        ),
        Agent(
            id: "main",
            name: "主助手",
            description: "通用 AI 助手",
            colorHex: "#007AFF",
            icon: "🤖"
        ),
        Agent(
            id: "claude",
            name: "Claude",
            description: "Anthropic Claude",
            colorHex: "#8E44AD",
            icon: "🧠"
        )
    ]
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
