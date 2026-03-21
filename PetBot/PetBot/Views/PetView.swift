// PetView.swift
// 宠物主视图 - 移除内置气泡，使用独立窗口

import SwiftUI

struct PetView: View {
    @StateObject private var viewModel = AgentViewModel()
    @State private var lastResponse: String = ""
    
    // 引用宠物窗口以便定位气泡
    weak var petWindow: NSWindow?
    
    var body: some View {
        ZStack {
            // 宠物主体
            petContent
        }
        .frame(width: AppConfiguration.petWindowSize.width, 
               height: AppConfiguration.petWindowSize.height)
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("toggleInput"))) { _ in
            toggleInput()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("showBubble"))) { notification in
            if let text = notification.object as? String {
                showBubble(text: text)
            }
        }
    }
    
    // MARK: - Subviews
    private var petContent: some View {
        VStack(spacing: 4) {
            // 图片自动适应大小
            PetImageView(imagePath: AppConfiguration.petImagePath)
            
            AgentNameLabel(name: viewModel.currentAgent.name)
        }
    }
    
    // MARK: - Actions
    private func toggleInput() {
        // 关闭气泡
        BubbleWindowController.shared.hide()
        
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
            
            await MainActor.run {
                // 获取最后一个非用户消息
                if let lastMessage = viewModel.messages.last(where: { !$0.isUser }) {
                    lastResponse = lastMessage.content
                    showBubble(text: lastResponse)
                    AppLogger.success("显示气泡: \(lastResponse.prefix(50))...")
                } else if let error = viewModel.errorMessage {
                    lastResponse = "❌ \(error)"
                    showBubble(text: lastResponse)
                    AppLogger.error("显示错误: \(error)")
                }
            }
        }
    }
    
    private func showBubble(text: String) {
        BubbleWindowController.shared.show(
            text: text,
            anchorWindow: petWindow
        )
    }
}

// MARK: - Subviews
struct PetImageView: View {
    let imagePath: String
    
    var body: some View {
        if let img = NSImage(contentsOfFile: imagePath) {
            Image(nsImage: img)
                .resizable()
                .aspectRatio(contentMode: .fit) // 保持比例
                .frame(width: img.size.width, height: img.size.height) // 实际尺寸
                .shadow(radius: 8, x: 0, y: 4)
        } else {
            Image(systemName: "cat.fill")
                .resizable()
                .scaledToFit()
                .foregroundColor(.orange)
                .frame(width: 200, height: 260)
        }
    }
}

struct AgentNameLabel: View {
    let name: String
    
    var body: some View {
        Text(name)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.white)
            .shadow(color: .black.opacity(0.8), radius: 2, x: 0, y: 1)
            .padding(.horizontal, 4)
    }
}
