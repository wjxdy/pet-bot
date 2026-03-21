// SettingsView.swift
// 设置视图 - 简化版

import SwiftUI

struct SettingsView: View {
    @ObservedObject var agentViewModel: AgentViewModel
    @Environment(\.dismiss) var dismiss
    
    // 使用简单的 @State 而不是 @AppStorage 来测试
    @State private var autoHideTime: Double = 10
    @State private var offsetX: Double = 0
    @State private var offsetY: Double = 5
    
    var body: some View {
        VStack {
            Text("PetBot 设置")
                .font(.title)
                .padding()
            
            List {
                Section("气泡设置") {
                    Picker("自动消失时间", selection: $autoHideTime) {
                        Text("5秒").tag(5.0)
                        Text("10秒").tag(10.0)
                        Text("15秒").tag(15.0)
                        Text("30秒").tag(30.0)
                        Text("永不").tag(-1.0)
                    }
                    
                    HStack {
                        Text("X 偏移: \(Int(offsetX))")
                        Slider(value: $offsetX, in: -100...100, step: 1)
                    }
                    
                    HStack {
                        Text("Y 偏移: \(Int(offsetY))")
                        Slider(value: $offsetY, in: -50...100, step: 1)
                    }
                }
                
                Section("Agent") {
                    ForEach(agentViewModel.availableAgents) { agent in
                        Button(action: {
                            agentViewModel.switchAgent(agent)
                        }) {
                            HStack {
                                Text(agent.icon)
                                Text(agent.name)
                                if agent.id == agentViewModel.currentAgent.id {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            
            Button("完成") {
                dismiss()
            }
            .padding()
        }
        .frame(width: 400, height: 500)
    }
}
