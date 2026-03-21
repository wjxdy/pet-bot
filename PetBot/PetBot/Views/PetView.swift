// PetView.swift
// 宠物主视图

import SwiftUI

struct PetView: View {
    @StateObject private var viewModel = AgentViewModel()
    @State private var showInputWindow = false
    @State private var showBubble = false
    @State private var lastResponse: String = ""
    
    var body: some View {
        ZStack {
            // 宠物主体
            petContent
            
            // 对话气泡
            if showBubble, !lastResponse.isEmpty {
                BubbleView(
                    text: lastResponse,
                    onClose: { showBubble = false }
                )
                .position(x: 260, y: 200)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(width: AppConfiguration.petWindowSize.width, 
               height: AppConfiguration.petWindowSize.height)
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("toggleInput"))) { _ in
            toggleInput()
        }
    }
    
    // MARK: - Subviews
    private var petContent: some View {
        VStack(spacing: 8) {
            Spacer()
            
            PetImageView(imagePath: AppConfiguration.petImagePath)
                .frame(width: 130, height: 130)
            
            AgentNameLabel(name: viewModel.currentAgent.name)
        }
    }
    
    // MARK: - Actions
    private func toggleInput() {
        if showBubble {
            withAnimation { showBubble = false }
        }
        
        if InputWindowController.shared.isVisible {
            InputWindowController.shared.hide()
        } else {
            InputWindowController.shared.show(viewModel: viewModel) { message in
                handleMessage(message)
            }
        }
    }
    
    private func handleMessage(_ message: String) {
        Task {
            await viewModel.sendMessage(message)
            
            // 延迟一下确保消息已更新
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
            
            await MainActor.run {
                // 显示最后一个非用户消息
                if let lastMessage = viewModel.messages.last(where: { !$0.isUser }) {
                    lastResponse = lastMessage.content
                    withAnimation {
                        showBubble = true
                    }
                    AppLogger.success("显示气泡: \(lastResponse.prefix(50))...")
                } else if let error = viewModel.errorMessage {
                    // 显示错误信息
                    lastResponse = "❌ \(error)"
                    withAnimation {
                        showBubble = true
                    }
                    AppLogger.error("显示错误: \(error)")
                } else {
                    AppLogger.error("没有消息可显示")
                }
            }
        }
    }
}

// MARK: - Subviews
struct PetImageView: View {
    let imagePath: String
    
    var body: some View {
        if let img = NSImage(contentsOfFile: imagePath) {
            Image(nsImage: img)
                .resizable()
                .scaledToFit()
                .shadow(radius: 8, x: 0, y: 4)
        } else {
            Image(systemName: "cat.fill")
                .resizable()
                .scaledToFit()
                .foregroundColor(.orange)
        }
    }
}

struct AgentNameLabel: View {
    let name: String
    
    var body: some View {
        Text(name)
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.white)
            .shadow(color: .black.opacity(0.8), radius: 2, x: 0, y: 1)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .padding(.bottom, 20)
    }
}

// MARK: - Bubble View
struct BubbleView: View {
    let text: String
    let onClose: () -> Void
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 6) {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.black)
            }
            .buttonStyle(PlainButtonStyle())
            
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.black)
                .lineSpacing(4)
                .frame(maxWidth: AppConfiguration.bubbleMaxWidth, alignment: .leading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(bubbleBackground)
        .frame(width: AppConfiguration.bubbleMaxWidth + 40)
    }
    
    private var bubbleBackground: some View {
        ZStack {
            // 阴影
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.2))
                .offset(x: 3, y: 3)
            
            // 背景
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white)
            
            // 边框
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.black, lineWidth: 2.5)
        }
    }
}
