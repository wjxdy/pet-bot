// BubbleWindow.swift
// 独立的气泡窗口 - 使用 AppKit 原生方法

import SwiftUI
import AppKit

@MainActor
class BubbleWindowController: NSObject {
    static let shared = BubbleWindowController()
    
    private var window: NSPanel?
    private var currentText: String = ""
    private var isPositioned = false
    private var hideTimer: Timer? // 自动隐藏定时器
    
    var isVisible: Bool {
        window?.isVisible ?? false
    }
    
    func show(text: String, anchorWindow: NSWindow?) {
        currentText = text
        
        // 创建或获取窗口
        if window == nil {
            createWindow()
            isPositioned = false
        }
        
        // 更新内容
        updateContent(text: text)
        
        // 定位（只在第一次）
        if !isPositioned {
            positionNearAnchor(anchorWindow)
            isPositioned = true
        }
        
        // 显示
        window?.orderFront(nil)
        window?.alphaValue = 1.0
        
        // 重置自动隐藏定时器（10秒）
        resetHideTimer()
        
        print("[PetBot] 气泡显示: \(text.prefix(30))...")
    }
    
    func hide() {
        window?.orderOut(nil)
        hideTimer?.invalidate()
        hideTimer = nil
    }
    
    func close() {
        window?.close()
        window = nil
        isPositioned = false
        hideTimer?.invalidate()
        hideTimer = nil
    }
    
    private func resetHideTimer() {
        // 取消之前的定时器
        hideTimer?.invalidate()
        
        // 获取配置的时间，-1 表示永不消失
        let seconds = AppConfiguration.bubbleAutoHideSeconds
        guard seconds > 0 else { return }
        
        // 创建新的定时器
        hideTimer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                print("[PetBot] 气泡 \(Int(seconds)) 秒无新消息，自动隐藏")
                self?.hide()
            }
        }
    }
    
    private func createWindow() {
        // 创建窗口内容
        let contentView = BubbleContentView(
            text: Binding(
                get: { self.currentText },
                set: { self.currentText = $0 }
            ),
            onClose: { [weak self] in
                self?.hide()
            }
        )
        
        let hostingView = NSHostingView(rootView: contentView)
        hostingView.frame = NSRect(x: 0, y: 0, width: 260, height: 200)
        
        // 创建窗口
        let window = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 260, height: 200),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        window.contentView = hostingView
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isMovableByWindowBackground = true
        
        self.window = window
    }
    
    private func updateContent(text: String) {
        guard let hostingView = window?.contentView as? NSHostingView<BubbleContentView> else { return }
        
        // 重新创建视图以更新内容
        let newView = BubbleContentView(
            text: Binding(
                get: { text },
                set: { _ in }
            ),
            onClose: { [weak self] in
                self?.hide()
            }
        )
        hostingView.rootView = newView
        
        // 调整窗口大小以适应内容
        let size = hostingView.fittingSize
        var frame = window?.frame ?? NSRect.zero
        frame.size = NSSize(width: max(260, size.width), height: max(80, size.height))
        window?.setFrame(frame, display: true)
    }
    
    private func positionNearAnchor(_ anchorWindow: NSWindow?) {
        guard let window = window else { return }
        
        if let anchor = anchorWindow {
            // 获取锚定窗口的屏幕坐标
            let anchorFrame = anchor.frame
            
            // 使用配置的偏移量
            let offsetX = AppConfiguration.bubbleOffsetX
            let offsetY = AppConfiguration.bubbleOffsetY
            
            // 气泡位置：宠物左上角 + 偏移
            let x = anchorFrame.origin.x + offsetX
            let y = anchorFrame.origin.y + anchorFrame.height + offsetY
            
            window.setFrameOrigin(NSPoint(x: x, y: y))
            print("[PetBot] 气泡位置: (\(x), \(y)), 偏移: (\(offsetX), \(offsetY))")
        }
    }
}

// MARK: - SwiftUI Content View
struct BubbleContentView: View {
    @Binding var text: String
    let onClose: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 关闭按钮
            HStack {
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.black)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // 内容
            ScrollView {
                Text(text.isEmpty ? "(等待回复...)" : text)
                    .font(.system(size: 14))
                    .foregroundColor(text.isEmpty ? .gray : .black)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 220, alignment: .leading)
                    .padding(.trailing, 8)
            }
            .frame(maxHeight: 300)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.black.opacity(0.2), lineWidth: 1)
                )
        )
    }
}
