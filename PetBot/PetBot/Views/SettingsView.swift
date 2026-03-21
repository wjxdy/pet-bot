// SettingsView.swift
// 设置视图

import SwiftUI
import AppKit

class SettingsViewModel: ObservableObject {
    @AppStorage("bubbleAutoHideSeconds") var bubbleAutoHideSeconds: Double = 10.0
    @AppStorage("petInitialX") var petInitialX: Double = 1000
    @AppStorage("petInitialY") var petInitialY: Double = 100
    @AppStorage("bubbleOffsetX") var bubbleOffsetX: Double = 0
    @AppStorage("bubbleOffsetY") var bubbleOffsetY: Double = 5
    @AppStorage("selectedAgentId") var selectedAgentId: String = "search"
    @AppStorage("autoReadAgentName") var autoReadAgentName: Bool = true
    
    let timeOptions: [Double] = [5, 10, 15, 30, 60]
    @Published var availableAgents: [Agent] = []
    
    init() {
        loadAgents()
    }
    
    func loadAgents() {
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
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text("PetBot 设置")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button("完成") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // 内容区
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // 气泡设置
                    GroupBox(label: Text("气泡设置").font(.headline)) {
                        VStack(alignment: .leading, spacing: 16) {
                            // 自动消失时间
                            VStack(alignment: .leading, spacing: 8) {
                                Text("自动消失时间")
                                    .font(.subheadline)
                                Picker("", selection: $settings.bubbleAutoHideSeconds) {
                                    Text("5秒").tag(5.0)
                                    Text("10秒").tag(10.0)
                                    Text("15秒").tag(15.0)
                                    Text("30秒").tag(30.0)
                                    Text("60秒").tag(60.0)
                                    Text("永不").tag(-1.0)
                                }
                                .pickerStyle(SegmentedPickerStyle())
                            }
                            
                            Divider()
                            
                            // 偏移设置
                            HStack {
                                Text("相对宠物 X 偏移")
                                Spacer()
                                TextField("0", value: $settings.bubbleOffsetX, formatter: NumberFormatter())
                                    .frame(width: 80)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .multilineTextAlignment(.trailing)
                            }
                            
                            HStack {
                                Text("相对宠物 Y 偏移")
                                Spacer()
                                TextField("5", value: $settings.bubbleOffsetY, formatter: NumberFormatter())
                                    .frame(width: 80)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .multilineTextAlignment(.trailing)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // Pet 设置
                    GroupBox(label: Text("Pet 设置").font(.headline)) {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("初始 X 位置")
                                Spacer()
                                TextField("1000", value: $settings.petInitialX, formatter: NumberFormatter())
                                    .frame(width: 100)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .multilineTextAlignment(.trailing)
                            }
                            
                            HStack {
                                Text("初始 Y 位置")
                                Spacer()
                                TextField("100", value: $settings.petInitialY, formatter: NumberFormatter())
                                    .frame(width: 100)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .multilineTextAlignment(.trailing)
                            }
                            
                            Toggle("自动读取 OpenClaw Agent 名字", isOn: $settings.autoReadAgentName)
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // Agent 设置
                    GroupBox(label: Text("Agent 设置").font(.headline)) {
                        VStack(alignment: .leading, spacing: 16) {
                            Picker("默认 Agent", selection: $settings.selectedAgentId) {
                                ForEach(settings.availableAgents) { agent in
                                    Text("\(agent.icon) \(agent.name)")
                                        .tag(agent.id)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // 重置按钮
                    HStack {
                        Spacer()
                        Button(action: { settings.resetToDefaults() }) {
                            Label("恢复默认设置", systemImage: "arrow.counterclockwise")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(LinkButtonStyle())
                        Spacer()
                    }
                    .padding(.top, 8)
                }
                .padding()
            }
        }
        .frame(width: 450, height: 550)
    }
}
