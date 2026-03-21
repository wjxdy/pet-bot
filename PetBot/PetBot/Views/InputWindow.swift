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
                .foregroundColor(.gray)
            
            // 输入框
            TextField("给小米鼠发消息...", text: $text)
                .font(.system(size: 18))
                .foregroundColor(.black)
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
                        .foregroundColor(.gray)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // 发送按钮
            Button(action: send) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
                    .background(
                        Circle()
                            .fill(text.isEmpty ? Color.gray.opacity(0.3) : Color.blue)
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(width: 680)
        .background(Color.white) // 白色背景
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
        .onAppear {
            isFocused = true
        }
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
    
    private var window: NSWindow?
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
        
        // 激活应用
        NSApp.activate(ignoringOtherApps: true)
        
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
        
        // 使用 NSWindow 而不是 NSPanel，更容易处理焦点
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 680, height: 60),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        window.contentView = hostingController.view
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false // SwiftUI 处理阴影
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        // 居中显示
        positionWindowCenter(window)
        
        self.window = window
    }
    
    private func positionWindowCenter(_ window: NSWindow) {
        guard let screen = NSScreen.main else { return }
        
        let screenRect = screen.visibleFrame
        let windowSize = window.frame.size
        
        // Spotlight 风格：水平居中，垂直偏上
        let x = screenRect.midX - windowSize.width / 2
        let y = screenRect.maxY * 0.65 - windowSize.height / 2
        
        window.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
