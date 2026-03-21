// InputWindow.swift
// 输入窗口 - 修复焦点问题

import Cocoa

class InputWindowController: NSObject, NSWindowDelegate {
    static let shared = InputWindowController()
    
    private var window: NSWindow?
    private var textField: NSTextField?
    private var onSendCallback: ((String) -> Void)?
    
    var isVisible: Bool {
        window?.isVisible ?? false
    }
    
    func show(viewModel: AgentViewModel, onSend: @escaping (String) -> Void) {
        self.onSendCallback = onSend
        
        if window == nil {
            createWindow()
        }
        
        guard let window = window, let textField = textField else { return }
        
        // 关键：先激活应用
        NSApp.activate(ignoringOtherApps: true)
        
        // 显示窗口
        window.makeKeyAndOrderFront(nil)
        
        // 关键：确保窗口成为 key window 后再设置第一响应者
        DispatchQueue.main.async {
            window.makeFirstResponder(textField)
        }
    }
    
    func hide() {
        window?.orderOut(nil)
    }
    
    func close() {
        window?.close()
        window = nil
        textField = nil
    }
    
    private func createWindow() {
        // 创建文本框
        let textField = NSTextField()
        textField.placeholderString = "输入消息..."
        textField.font = NSFont.systemFont(ofSize: 14)
        textField.isEditable = true
        textField.isSelectable = true
        textField.bezelStyle = .roundedBezel
        textField.translatesAutoresizingMaskIntoConstraints = false
        
        // 创建按钮
        let button = NSButton(title: "发送", target: self, action: #selector(sendMessage))
        button.bezelStyle = .rounded
        button.keyEquivalent = "\r"
        button.translatesAutoresizingMaskIntoConstraints = false
        
        // 容器
        let container = NSView()
        container.wantsLayer = true
        container.layer?.backgroundColor = NSColor.white.cgColor
        container.layer?.cornerRadius = 12
        container.layer?.shadowColor = NSColor.black.cgColor
        container.layer?.shadowOpacity = 0.3
        container.layer?.shadowRadius = 20
        container.layer?.shadowOffset = CGSize(width: 0, height: 10)
        container.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(textField)
        container.addSubview(button)
        
        // 约束
        NSLayoutConstraint.activate([
            container.widthAnchor.constraint(equalToConstant: 400),
            container.heightAnchor.constraint(equalToConstant: 60),
            
            textField.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            textField.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            textField.trailingAnchor.constraint(equalTo: button.leadingAnchor, constant: -12),
            
            button.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            button.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            button.widthAnchor.constraint(equalToConstant: 60),
            button.heightAnchor.constraint(equalToConstant: 32)
        ])
        
        // 创建窗口 - 使用 .titled 确保能接收输入
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 60),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "发送消息"
        window.contentView = container
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.delegate = self
        
        window.center()
        
        self.window = window
        self.textField = textField
    }
    
    @objc private func sendMessage() {
        guard let text = textField?.stringValue.trimmingCharacters(in: .whitespaces),
              !text.isEmpty else { return }
        onSendCallback?(text)
        textField?.stringValue = ""
        hide()
    }
    
    func windowDidBecomeKey(_ notification: Notification) {
        if let textField = textField {
            window?.makeFirstResponder(textField)
        }
    }
}
