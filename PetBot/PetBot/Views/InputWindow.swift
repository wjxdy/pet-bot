// InputWindow.swift
// 输入窗口控制器 - Spotlight 风格

import SwiftUI
import AppKit

// MARK: - SwiftUI Input View
struct SpotlightInputView: View {
    @State private var text = ""
    @FocusState private var isFocused: Bool
    let onSend: (String) -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // 搜索图标
            Image(systemName: "magnifyingglass")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
            
            // 输入框
            TextField("给小米鼠发消息...", text: $text)
                .font(.system(size: 18))
                .foregroundColor(.white)
                .focused($isFocused)
                .textFieldStyle(PlainTextFieldStyle())
                .onSubmit {
                    send()
                }
            
            // 清除按钮（有内容时显示）
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.5))
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // 发送按钮
            Button(action: send) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
                    .frame(width: 28, height: 28)
                    .background(
                        Circle()
                            .fill(text.isEmpty ? Color.white.opacity(0.3) : Color.white)
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(width: 680)
    }
    
    private func send() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        onSend(trimmed)
        text = ""
    }
}

// MARK: - Window Controller
@MainActor
class InputWindowController: NSObject {
    static let shared = InputWindowController()
    
    private var window: NSPanel?
    private var hostingController: NSHostingController<SpotlightInputView>?
    private var onSendCallback: ((String) -> Void)?
    
    var isVisible: Bool {
        window?.isVisible ?? false
    }
    
    func show(viewModel: AgentViewModel, onSend: @escaping (String) -> Void) {
        self.onSendCallback = onSend
        
        if window == nil {
            createWindow()
        }
        
        // 激活应用并显示窗口
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
        
        // 延迟一点确保窗口准备好后设置焦点
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            if let hostingView = self?.window?.contentView as? NSHostingView<SpotlightInputView> {
                // 触发 SwiftUI 焦点
                self?.window?.makeFirstResponder(hostingView)
            }
        }
    }
    
    func hide() {
        window?.orderOut(nil)
    }
    
    func close() {
        window?.close()
        window = nil
        hostingController = nil
    }
    
    private func createWindow() {
        let inputView = SpotlightInputView(
            onSend: { [weak self] text in
                self?.onSendCallback?(text)
                self?.hide()
            },
            onDismiss: { [weak self] in
                self?.hide()
            }
        )
        
        let hostingController = NSHostingController(rootView: inputView)
        self.hostingController = hostingController
        
        // 创建 NSPanel - 使用 borderless 但不使用 nonactivatingPanel
        let window = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 680, height: 60),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        window.contentView = hostingController.view
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isMovableByWindowBackground = false // Spotlight 风格通常不拖动
        
        // 设置圆角和背景
        window.contentView?.wantsLayer = true
        window.contentView?.layer?.cornerRadius = 16
        window.contentView?.layer?.masksToBounds = true
        window.contentView?.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.75).cgColor
        
        // 添加强阴影效果
        window.hasShadow = true
        
        // 居中显示
        positionWindowCenter(window)
        
        self.window = window
    }
    
    private func positionWindowCenter(_ window: NSWindow) {
        guard let screen = NSScreen.main else { return }
        
        let screenRect = screen.visibleFrame
        let windowSize = window.frame.size
        
        // Spotlight 风格：水平居中，垂直偏上（屏幕高度的 2/3 处）
        let x = screenRect.midX - windowSize.width / 2
        let y = screenRect.maxY * 0.65 - windowSize.height / 2
        
        window.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
