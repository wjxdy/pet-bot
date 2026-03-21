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
            AppLogger.info("创建气泡窗口")
        }
        
        // 更新内容
        updateContent(text: text)
        AppLogger.info("更新气泡内容: \(text.prefix(50))...")
        
        // 只在第一次显示时定位到宠物窗口
        if !isPositioned {
            positionWindow(anchorWindow: anchorWindow)
            isPositioned = true
            AppLogger.info("定位气泡窗口到宠物左上方")
        }
        
        // 显示窗口
        window?.orderFront(nil)
        AppLogger.info("气泡窗口已显示")
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
        // 创建初始气泡视图
        let bubbleView = BubbleView(
            text: "初始化...",
            onClose: { [weak self] in
                self?.hide()
            }
        )
        
        let hostingController = NSHostingController(rootView: bubbleView)
        self.hostingController = hostingController
        
        // 计算窗口大小 - 使用 SwiftUI 的 idealSize
        let windowSize = NSSize(width: 240, height: 100)
        
        // 创建无边框浮动窗口
        let window = NSPanel(
            contentRect: NSRect(origin: .zero, size: windowSize),
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
        AppLogger.info("气泡窗口创建完成，大小: \(windowSize)")
    }
    
    private func updateContent(text: String) {
        // 在主线程更新内容
        DispatchQueue.main.async { [weak self] in
            let bubbleView = BubbleView(
                text: text,
                onClose: { [weak self] in
                    self?.hide()
                }
            )
            self?.hostingController?.rootView = bubbleView
        }
    }
    
    private func positionWindow(anchorWindow: NSWindow?) {
        guard let window = window else { 
            AppLogger.error("气泡窗口不存在")
            return 
        }
        
        if let anchor = anchorWindow {
            // macOS 坐标原点在左下角
            // 宠物窗口的底部 Y 坐标
            let anchorFrame = anchor.frame
            let bubbleX = anchorFrame.origin.x + 10 // 左边偏一点
            // 气泡放在宠物上方，所以 Y = 宠物Y + 宠物高度 + 间距
            let bubbleY = anchorFrame.origin.y + anchorFrame.height + 10
            
            window.setFrameOrigin(NSPoint(x: bubbleX, y: bubbleY))
            AppLogger.info("气泡位置: x=\(bubbleX), y=\(bubbleY), 宠物位置: x=\(anchorFrame.origin.x), y=\(anchorFrame.origin.y), 高=\(anchorFrame.height)")
        } else {
            // 如果没有锚定窗口，显示在屏幕中央
            let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
            let x = screen.midX - 120
            let y = screen.midY
            window.setFrameOrigin(NSPoint(x: x, y: y))
            AppLogger.info("气泡位置(默认): x=\(x), y=\(y)")
        }
    }
}

// MARK: - Bubble View
struct BubbleView: View {
    let text: String
    let onClose: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 关闭按钮 - 右上角
            HStack {
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.black)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // 消息文本
            if !text.isEmpty {
                Text(text)
                    .font(.system(size: 14))
                    .foregroundColor(.black)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 200, alignment: .leading)
            } else {
                Text("(无内容)")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.2))
                    .offset(x: 3, y: 3)
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white)
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.black, lineWidth: 2.5)
            }
        )
        .frame(minWidth: 200, maxWidth: 240, minHeight: 60)
    }
}
