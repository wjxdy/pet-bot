// SettingsView.swift
// 设置视图

import SwiftUI
import AppKit

class SettingsViewModel: ObservableObject {
    // 1. 气泡消失时间（秒）
    @AppStorage("bubbleAutoHideSeconds") var bubbleAutoHideSeconds: Double = 10.0
    
    // 2. Pet 初始位置
    @AppStorage("petInitialX") var petInitialX: Double = 1000
    @AppStorage("petInitialY") var petInitialY: Double = 100
    
    // 3. 气泡相对位置偏移
    @AppStorage("bubbleOffsetX") var bubbleOffsetX: Double = 0
    @AppStorage("bubbleOffsetY") var bubbleOffsetY: Double = 5
    
    // 4. 当前 Agent
    @AppStorage("selectedAgentId") var selectedAgentId: String = "search"
    
    // 5. 是否自动读取 OpenClaw agent 名字
    @AppStorage("autoReadAgentName") var autoReadAgentName: Bool = true
    
    // 可选的消失时间选项
    let timeOptions: [Double] = [5, 10, 15, 30, 60]
    
    // OpenClaw agents 列表
    @Published var availableAgents: [Agent] = []
    
    init() {
        loadAgents()
    }
    
    func loadAgents() {
        // 从 OpenClaw 获取可用 agents
        availableAgents = [
            Agent(id: "search", name: "小米鼠", description: "默认助手", colorHex: "#FF9500", icon: "🐭"),
            Agent(id: "shennong", name: "神农", description: "AI 功能实验师", colorHex: "#FF6B35", icon: "🌿"),
            Agent(id: "main", name: "主助手", description: "通用 AI 助手", colorHex: "#007AFF", icon: "🤖"),
            Agent(id: "claude", name: "Claude", description: "Anthropic Claude", colorHex: "#8E44AD", icon: "🧠")
        ]
    }
    
    func resetToDefaults() {
        bubbleAutoHideSeconds = 10
        petInitialX = 1000
        petInitialY = 100
        bubbleOffsetX = 0
        bubbleOffsetY = 5
        selectedAgentId = "search"
        autoReadAgentName = true
    }
}

struct SettingsView: View {
    @StateObject private var settings = SettingsViewModel()
    @ObservedObject var agentViewModel: AgentViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: - 气泡设置
                Section(header: Text("气泡设置")) {
                    Picker("自动消失时间", selection: $settings.bubbleAutoHideSeconds) {
                        Text("5秒").tag(5.0)
                        Text("10秒").tag(10.0)
                        Text("15秒").tag(15.0)
                        Text("30秒").tag(30.0)
                        Text("60秒").tag(60.0)
                        Text("永不").tag(-1.0)
                    }
                    
                    HStack {
                        Text("相对宠物 X 偏移")
                        Spacer()
                        TextField("", value: $settings.bubbleOffsetX, formatter: NumberFormatter())
                            .frame(width: 60)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("相对宠物 Y 偏移")
                        Spacer()
                        TextField("", value: $settings.bubbleOffsetY, formatter: NumberFormatter())
                            .frame(width: 60)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                // MARK: - Pet 设置
                Section(header: Text("Pet 设置")) {
                    HStack {
                        Text("初始 X 位置")
                        Spacer()
                        TextField("", value: $settings.petInitialX, formatter: NumberFormatter())
                            .frame(width: 80)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("初始 Y 位置")
                        Spacer()
                        TextField("", value: $settings.petInitialY, formatter: NumberFormatter())
                            .frame(width: 80)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    Toggle("自动读取 OpenClaw Agent 名字", isOn: $settings.autoReadAgentName)
                }
                
                // MARK: - Agent 设置
                Section(header: Text("Agent 设置")) {
                    Picker("默认 Agent", selection: $settings.selectedAgentId) {
                        ForEach(settings.availableAgents) { agent in
                            HStack {
                                Text(agent.icon)
                                Text(agent.name)
                            }
                            .tag(agent.id)
                        }
                    }
                    .onChange(of: settings.selectedAgentId) { newId in
                        if let agent = settings.availableAgents.first(where: { $0.id == newId }) {
                            agentViewModel.switchAgent(agent)
                        }
                    }
                }
                
                // MARK: - 重置
                Section {
                    Button("恢复默认设置") {
                        settings.resetToDefaults()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("PetBot 设置")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("完成") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .frame(width: 450, height: 500)
    }
}
