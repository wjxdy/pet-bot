// InputWindow.swift
// 输入窗口控制器 - 可拖动带阴影

import SwiftUI
import AppKit

struct DraggableInputView: View {
    @State private var text: String = ""
    let onSend: (String) -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            TextField("输入消息...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.system(size: 16))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white)
                .cornerRadius(8)
                .onSubmit {
                    submit()
                }
            
            Button(action: submit) {
                Text("发送")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(text.isEmpty ? Color.gray : Color.blue)
                    .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(text.isEmpty)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.windowBackgroundColor))
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        )
    }
    
    private func submit() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        onSend(trimmed)
        text = ""
    }
}

@MainActor
class InputWindowController: NSObject, NSWindowDelegate {
    static let shared = InputWindowController()
    
    private var window: NSPanel?
    private var onSendCallback: ((String) -> Void)?
    
    var isVisible: Bool {
        window?.isVisible ?? false
    }
    
    func show(viewModel: AgentViewModel, onSend: @escaping (String) -> Void) {
        self.onSendCallback = onSend
        
        if window == nil {
            createWindow()
        }
        
        // 激活并显示
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }
    
    func hide() {
        window?.orderOut(nil)
    }
    
    func close() {
        window?.close()
        window = nil
    }
    
    private func createWindow() {
        let contentView = DraggableInputView { [weak self] text in
            self?.onSendCallback?(text)
            self?.hide()
        }
        
        let hostingController = NSHostingController(rootView: contentView)
        
        // 使用 NSPanel 无边框但可拖动
        let window = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 80),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        window.contentView = hostingController.view
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true  // 启用阴影
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isMovableByWindowBackground = true  // 允许拖动
        
        // 居中显示
        window.center()
        
        self.window = window
    }
}
