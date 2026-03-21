// SettingsView.swift
// 设置视图（预留）

import SwiftUI

struct SettingsView: View {
    @ObservedObject var agentManager: AgentManager
    @State private var selectedHotkey = "⌘+Option+Space"
    
    var body: some View {
        TabView {
            // 通用设置
            Form {
                Section("快捷键") {
                    Picker("唤起对话", selection: $selectedHotkey) {
                        Text("⌘+Option+Space").tag("⌘+Option+Space")
                        Text("⌘+Shift+Space").tag("⌘+Shift+Space")
                        Text("⌃+Option+Space").tag("⌃+Option+Space")
                    }
                }
                
                Section("宠物") {
                    Toggle("开机自启动", isOn: .constant(false))
                    Toggle("显示动画效果", isOn: .constant(true))
                }
            }
            .tabItem {
                Label("通用", systemImage: "gear")
            }
            
            // Agent 设置
            Form {
                Section("默认 Agent") {
                    Picker("启动时使用", selection: .constant(0)) {
                        ForEach(agentManager.availableAgents) { agent in
                            Text(agent.name).tag(agent.id)
                        }
                    }
                }
                
                Section("自定义 Agent") {
                    Button("添加 Agent") {
                        // 添加自定义 Agent
                    }
                }
            }
            .tabItem {
                Label("Agent", systemImage: "cpu")
            }
            
            // 关于
            VStack(spacing: 20) {
                Image(systemName: "bubble.left.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.orange)
                
                Text("PetBot")
                    .font(.title)
                
                Text("你的桌面 AI 宠物")
                    .foregroundColor(.secondary)
                
                Text("版本 1.0.0")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .tabItem {
                Label("关于", systemImage: "info.circle")
            }
        }
        .padding()
        .frame(width: 400, height: 300)
    }
}
