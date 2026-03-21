// PetView.swift
// 宠物主视图 - 名字在图片上方

import SwiftUI

struct PetView: View {
    @ObservedObject var agentManager: AgentManager
    @State private var showResponseBubble = false
    @State private var currentResponseText = ""
    
    var body: some View {
        ZStack {
            // 宠物和名字 - 底部居中，图片在上，名字在下
            VStack(spacing: 8) {
                Spacer() // 上方留白，把宠物推到底部
                
                // === 图片在上 ===
                PetImage()
                    .frame(width: 130, height: 130)
                
                // === 名字在下（透明背景+阴影）===
                Text(agentManager.currentAgent.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.8), radius: 2, x: 0, y: 1)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .padding(.bottom, 20)
            }
            
            // 回复气泡 - 显示在宠物右上方
            if showResponseBubble && !currentResponseText.isEmpty {
                DialogBubble(
                    text: currentResponseText,
                    onClose: {
                        withAnimation {
                            showResponseBubble = false
                        }
                    }
                )
                .position(x: 260, y: 200) // 宠物右上方位置
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

// 对话气泡 - 像素风格
struct DialogBubble: View {
    let text: String
    let onClose: () -> Void
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 6) {
            // 关闭按钮
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.black)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.trailing, 6)
            
            // 消息文本
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.black)
                .lineSpacing(4)
                .frame(maxWidth: 220, alignment: .leading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            ZStack {
                // 阴影层（右下偏移）
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.2))
                    .offset(x: 3, y: 3)
                
                // 主背景（白色）
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white)
                
                // 黑色边框
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.black, lineWidth: 2.5)
            }
        )
        .frame(width: 260)
        // 小尾巴指向宠物
        .overlay(
            Triangle()
                .fill(Color.white)
                .stroke(Color.black, lineWidth: 2.5)
                .frame(width: 16, height: 10)
                .rotationEffect(.degrees(180))
                .offset(x: -60, y: 48),
            alignment: .bottom
        )
    }
}

// 三角形形状（用于气泡尾巴）
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
