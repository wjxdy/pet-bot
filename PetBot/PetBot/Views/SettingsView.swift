// SettingsView.swift
// 设置视图

import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: AgentViewModel
    @State private var selectedHotkey = "⌥+Space"
    
    var body: some View {
        NavigationView {
            Form {
                Section("快捷键") {
                    Picker("唤起输入框", selection: $selectedHotkey) {
                        Text("⌥+Space").tag("⌥+Space")
                        Text("⌘+⇧+Space").tag("⌘+⇧+Space")
                    }
                }
                
                Section("默认 Agent") {
                    Picker("启动时使用", selection: Binding(
                        get: { viewModel.currentAgent.id },
                        set: { newId in
                            if let agent = viewModel.availableAgents.first(where: { $0.id == newId }) {
                                viewModel.switchAgent(agent)
                            }
                        }
                    )) {
                        ForEach(viewModel.availableAgents) { agent in
                            Text(agent.name).tag(agent.id)
                        }
                    }
                }
                
                Section("关于") {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("设置")
        }
        .frame(width: 400, height: 300)
    }
}
