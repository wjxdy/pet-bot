// InputWindow.swift
// 输入窗口 - 使用标准窗口确保可输入

import SwiftUI
import AppKit

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
        
        // 激活应用并显示窗口
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
        
        // 延迟设置焦点
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.textField?.becomeFirstResponder()
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
        // 创建容器视图
        let containerView = NSView()
        containerView.wantsLayer = true
        containerView.layer?.backgroundColor = NSColor.white.cgColor
        containerView.layer?.cornerRadius = 12
        containerView.layer?.shadowColor = NSColor.black.cgColor
        containerView.layer?.shadowOpacity = 0.2
        containerView.layer?.shadowRadius = 15
        containerView.layer?.shadowOffset = CGSize(width: 0, height: 5)
        
        // 创建文本框
        let textField = NSTextField()
        textField.placeholderString = "输入消息..."
        textField.font = NSFont.systemFont(ofSize: 14)
        textField.isEditable = true
        textField.isSelectable = true
        textField.bezelStyle = .roundedBezel
        textField.translatesAutoresizingMaskIntoConstraints = false
        
        // 创建发送按钮
        let button = NSButton(title: "发送", target: self, action: #selector(sendMessage))
        button.bezelStyle = .rounded
        button.keyEquivalent = "\r"
        button.translatesAutoresizingMaskIntoConstraints = false
        
        // 添加到容器
        containerView.addSubview(textField)
        containerView.addSubview(button)
        
        // 布局
        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            textField.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            textField.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16),
            textField.trailingAnchor.constraint(equalTo: button.leadingAnchor, constant: -8),
            
            button.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            button.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            button.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16),
            button.widthAnchor.constraint(equalToConstant: 60)
        ])
        
        // 创建窗口 - 使用标准 NSWindow 而不是 NSPanel
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 70),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        window.contentView = containerView
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isMovableByWindowBackground = true
        window.delegate = self
        
        // 居中显示
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
        // 窗口成为 key window 时设置焦点
        textField?.becomeFirstResponder()
    }
}
