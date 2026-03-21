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
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    GroupBox("气泡设置") {
                        VStack(alignment: .leading, spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("自动消失时间")
                                    .font(.subheadline)
                                Picker("", selection: $autoHideTime) {
                                    Text("5秒").tag(5.0)
                                    Text("10秒").tag(10.0)
                                    Text("15秒").tag(15.0)
                                    Text("30秒").tag(30.0)
                                    Text("永不").tag(-1.0)
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                .labelsHidden()
                            }

                            HStack {
                                Text("X 偏移")
                                Spacer()
                                Text("\(Int(offsetX))")
                                    .frame(width: 30, alignment: .trailing)
                                Slider(value: $offsetX, in: -100...100, step: 1)
                                    .frame(width: 150)
                            }

                            HStack {
                                Text("Y 偏移")
                                Spacer()
                                Text("\(Int(offsetY))")
                                    .frame(width: 30, alignment: .trailing)
                                Slider(value: $offsetY, in: -50...100, step: 1)
                                    .frame(width: 150)
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    GroupBox("Agent 选择") {
                        VStack(alignment: .leading, spacing: 8) {
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
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding()
            }
            
            Spacer()
            
            Button("完成") {
                dismiss()
            }
            .padding()
        }
        .frame(minWidth: 450, minHeight: 500)
    }
}
