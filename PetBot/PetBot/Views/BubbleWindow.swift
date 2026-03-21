// BubbleWindow.swift
// 独立的气泡窗口

import SwiftUI
import AppKit

@MainActor
class BubbleWindowController: NSObject {
    static let shared = BubbleWindowController()
    
    private var window: NSPanel?
    private var hostingController: NSHostingController<BubbleView>?
    private var isPositioned = false // 标记是否已设置过初始位置
    
    var isVisible: Bool {
        window?.isVisible ?? false
    }
    
    func show(text: String, anchorWindow: NSWindow?) {
        // 如果窗口不存在则创建
        if window == nil {
            createWindow()
            isPositioned = false
        }
        
        // 更新内容
        updateContent(text: text)
        
        // 只在第一次显示时定位到宠物窗口
        if !isPositioned {
            positionWindow(anchorWindow: anchorWindow)
            isPositioned = true
        }
        
        // 显示窗口
        window?.makeKeyAndOrderFront(nil)
    }
    
    func hide() {
        window?.orderOut(nil)
    }
    
    func close() {
        window?.close()
        window = nil
        hostingController = nil
        isPositioned = false
    }
    
    func resetPosition() {
        isPositioned = false
    }
    
    private func createWindow() {
        let bubbleView = BubbleView(
            text: "",
            onClose: { [weak self] in
                self?.hide()
            }
        )
        
        let hostingController = NSHostingController(rootView: bubbleView)
        self.hostingController = hostingController
        
        // 创建无边框浮动窗口
        let window = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 240, height: 150),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isMovableByWindowBackground = true
        window.contentViewController = hostingController
        
        self.window = window
    }
    
    private func updateContent(text: String) {
        let bubbleView = BubbleView(
            text: text,
            onClose: { [weak self] in
                self?.hide()
            }
        )
        hostingController?.rootView = bubbleView
    }
    
    private func positionWindow(anchorWindow: NSWindow?) {
        guard let window = window else { return }
        
        if let anchor = anchorWindow {
            // 定位到宠物窗口的左上方
            let anchorFrame = anchor.frame
            let bubbleX = anchorFrame.origin.x
            let bubbleY = anchorFrame.origin.y + anchorFrame.height + 10 // 上方10像素
            
            window.setFrameOrigin(NSPoint(x: bubbleX, y: bubbleY))
        }
    }
}

// MARK: - Bubble View
struct BubbleView: View {
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
            
            // 消息文本 - 带滚动
            ScrollView(.vertical, showsIndicators: true) {
                Text(text)
                    .font(.system(size: 14))
                    .foregroundColor(.black)
                    .lineSpacing(4)
                    .frame(maxWidth: 200, alignment: .leading)
                    .padding(.trailing, 4)
            }
            .frame(maxHeight: 300) // 最大高度
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(bubbleBackground)
        .frame(width: 240)
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
