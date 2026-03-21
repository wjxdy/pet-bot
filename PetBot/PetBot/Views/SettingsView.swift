// SettingsView.swift
// 设置视图 - 修复版

import SwiftUI

struct SettingsView: View {
    @ObservedObject var agentViewModel: AgentViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var autoHideTime: Double = 10
    @State private var offsetX: Double = 0
    @State private var offsetY: Double = 5
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题
            Text("PetBot 设置")
                .font(.title2)
                .fontWeight(.semibold)
                .padding()
            
            Divider()
            
            // 内容
            Form {
                Section("气泡设置") {
                    Picker("自动消失时间", selection: $autoHideTime) {
                        Text("5秒").tag(5.0)
                        Text("10秒").tag(10.0)
                        Text("15秒").tag(15.0)
                        Text("30秒").tag(30.0)
                        Text("永不").tag(-1.0)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    HStack {
                        Text("X 偏移")
                        Spacer()
                        Text("\(Int(offsetX))")
                        Slider(value: $offsetX, in: -100...100, step: 1)
                            .frame(width: 150)
                    }
                    
                    HStack {
                        Text("Y 偏移")
                        Spacer()
                        Text("\(Int(offsetY))")
                        Slider(value: $offsetY, in: -50...100, step: 1)
                            .frame(width: 150)
                    }
                }
                
                Section("Agent 选择") {
                    if agentViewModel.availableAgents.isEmpty {
                        Text("加载中...")
                            .foregroundColor(.gray)
                    } else {
                        ForEach(agentViewModel.availableAgents) { agent in
                            Button(action: {
                                agentViewModel.switchAgent(agent)
                            }) {
                                HStack {
                                    Text("\(agent.icon) \(agent.name)")
                                    Spacer()
                                    if agent.id == agentViewModel.currentAgent.id {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
            .padding()
            
            Spacer()
            
            Button("完成") {
                dismiss()
            }
            .padding()
        }
        .frame(width: 400, height: 450)
    }
}
