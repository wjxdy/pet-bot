// InputWindow.swift
// 输入窗口控制器 - 使用标准窗口确保可输入

import SwiftUI
import AppKit

struct SimpleInputView: View {
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
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(12)
        .shadow(radius: 10)
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
    
    private var window: NSWindow?
    private var onSendCallback: ((String) -> Void)?
    
    var isVisible: Bool {
        window?.isVisible ?? false
    }
    
    func show(viewModel: AgentViewModel, onSend: @escaping (String) -> Void) {
        self.onSendCallback = onSend
        
        if window == nil {
            createWindow()
        }
        
        // 窗口居中
        window?.center()
        
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
        let contentView = SimpleInputView { [weak self] text in
            self?.onSendCallback?(text)
            self?.hide()
        }
        
        let hostingController = NSHostingController(rootView: contentView)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 80),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "发送消息"
        window.contentViewController = hostingController
        window.delegate = self
        window.isReleasedWhenClosed = false
        
        self.window = window
    }
    
    func windowWillClose(_ notification: Notification) {
        // 窗口关闭时的处理
    }
}
