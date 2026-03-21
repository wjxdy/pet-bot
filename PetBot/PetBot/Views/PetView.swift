// PetView.swift
// 宠物主视图 - 名字在图片上方

import SwiftUI

struct PetView: View {
    @ObservedObject var agentManager: AgentManager
    @State private var showResponseBubble = false
    @State private var currentResponseText = ""
    
    var body: some View {
        ZStack {
            // 回复气泡
            if showResponseBubble && !currentResponseText.isEmpty {
                VStack {
                    DialogBubble(
                        text: currentResponseText,
                        onClose: {
                            withAnimation {
                                showResponseBubble = false
                            }
                        }
                    )
                    .padding(.top, 30)
                    Spacer()
                }
            }
            
            // 宠物和名字 - 底部居中，名字在上
            VStack(spacing: 6) {
                Spacer() // 上方留白，把宠物推到底部
                
                // === 名字在上 ===
                Text(agentManager.currentAgent.name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(agentManager.currentAgent.color))
                
                // === 图片在下 ===
                PetImage()
                    .frame(width: 130, height: 130)
                    .padding(.bottom, 20)
            }
        }
        .frame(width: 360, height: 400)
        .onReceive(NotificationCenter.default.publisher(for: .toggleChat)) { _ in
            toggleInput()
        }
    }
    
    private func toggleInput() {
        if showResponseBubble {
            withAnimation { showResponseBubble = false }
        }
        
        if InputWindowController.shared.isVisible {
            InputWindowController.shared.hide()
        } else {
            InputWindowController.shared.show(agentManager: agentManager) { msg in
                send(msg)
            }
        }
    }
    
    private func send(_ message: String) {
        Task {
            await agentManager.sendMessage(message)
            await MainActor.run {
                if let resp = agentManager.currentResponse {
                    currentResponseText = resp
                    agentManager.currentResponse = nil
                    withAnimation { showResponseBubble = true }
                }
            }
        }
    }
}

// 宠物图片
struct PetImage: View {
    private let path = "/Users/xulei/Desktop/new_a.png"
    
    var body: some View {
        if let img = NSImage(contentsOfFile: path) {
            Image(nsImage: img)
                .resizable()
                .scaledToFit()
                .shadow(radius: 8, x: 0, y: 4)
        } else {
            Image(systemName: "photo")
                .resizable()
                .scaledToFit()
                .foregroundColor(.gray)
        }
    }
}

// 对话气泡
struct DialogBubble: View {
    let text: String
    let onClose: () -> Void
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.trailing, 4)
            
            Text(text)
                .font(.system(size: 13))
                .lineSpacing(3)
                .frame(maxWidth: 240, alignment: .leading)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(radius: 8)
        )
        .frame(width: 280)
    }
}
