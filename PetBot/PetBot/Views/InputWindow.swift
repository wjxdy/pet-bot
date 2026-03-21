// InputWindow.swift
// 输入窗口 - 无边框设计 + 玻璃拟态

import Cocoa

@MainActor
class InputWindowController: NSObject, NSWindowDelegate {
    static let shared = InputWindowController()
    
    private var window: NSWindow?
    private var textField: NSTextField?
    private var onSendCallback: ((String) -> Void)?
    private var focusWorkItem: DispatchWorkItem?
    private let cornerRadius: CGFloat = 20
    
    var isVisible: Bool {
        window?.isVisible ?? false
    }
    
    func show(viewModel: AgentViewModel, onSend: @escaping (String) -> Void) {
        self.onSendCallback = onSend
        
        // 取消之前挂起的焦点任务
        focusWorkItem?.cancel()
        
        if window == nil {
            createWindow()
        }
        
        guard let window = window, let textField = textField else { return }
        
        // 关键：先激活应用
        NSApp.activate(ignoringOtherApps: true)
        
        // 显示窗口并使其成为 key window
        window.makeKeyAndOrderFront(nil)
        
        // 清除并准备输入框
        textField.stringValue = ""
        
        // 关键：多次尝试设置焦点，确保成功
        // 立即尝试一次
        attemptFocus()
        
        // 延迟再尝试几次，确保窗口真正成为 key window 后设置焦点
        let workItem = DispatchWorkItem { [weak self] in
            self?.attemptFocus()
        }
        focusWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: workItem)
        
        // 最后再尝试一次，处理边缘情况
        let finalWorkItem = DispatchWorkItem { [weak self] in
            self?.attemptFocus()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: finalWorkItem)
    }
    
    func hide() {
        focusWorkItem?.cancel()
        window?.orderOut(nil)
    }
    
    func close() {
        focusWorkItem?.cancel()
        window?.close()
        window = nil
        textField = nil
    }
    
    private func attemptFocus() {
        guard let window = window, let textField = textField else { return }
        
        // 确保窗口是 key window
        if !window.isKeyWindow {
            window.makeKeyAndOrderFront(nil)
        }
        
        // 尝试设置第一响应者
        window.makeFirstResponder(textField)
        
        // 额外：如果文本框支持，尝试开始编辑
        if textField.acceptsFirstResponder {
            textField.becomeFirstResponder()
        }
    }
    
    private func createWindow() {
        // 创建视觉特效背景
        let visualEffectView = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: 420, height: 70))
        visualEffectView.material = .hudWindow  // HUD 材质，深色玻璃效果
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.state = .active
        visualEffectView.wantsLayer = true
        visualEffectView.layer?.cornerRadius = cornerRadius
        visualEffectView.layer?.masksToBounds = true
        
        // 创建文本框 - 无边框样式
        let textField = FocusAwareTextField()
        textField.placeholderString = "输入消息..."
        textField.font = NSFont.systemFont(ofSize: 15, weight: .medium)
        textField.isEditable = true
        textField.isSelectable = true
        textField.bezelStyle = .roundedBezel
        textField.focusRingType = .none  // 无边框聚焦环
        textField.backgroundColor = NSColor.white.withAlphaComponent(0.15)
        textField.textColor = .white
        textField.placeholderAttributedString = NSAttributedString(
            string: "输入消息...",
            attributes: [
                .foregroundColor: NSColor.white.withAlphaComponent(0.5),
                .font: NSFont.systemFont(ofSize: 15)
            ]
        )
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.target = self
        textField.action = #selector(sendMessage)
        
        // 圆角文本框
        textField.wantsLayer = true
        textField.layer?.cornerRadius = 8
        textField.layer?.masksToBounds = true
        
        // 创建发送按钮
        let button = NSButton(title: "发送", target: self, action: #selector(sendMessage))
        button.bezelStyle = .rounded
        button.keyEquivalent = "\r"
        button.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
        button.contentTintColor = .white
        button.wantsLayer = true
        button.layer?.backgroundColor = NSColor.systemBlue.cgColor
        button.layer?.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        
        // 添加到视觉特效视图
        visualEffectView.addSubview(textField)
        visualEffectView.addSubview(button)
        
        // 约束
        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: visualEffectView.leadingAnchor, constant: 16),
            textField.centerYAnchor.constraint(equalTo: visualEffectView.centerYAnchor),
            textField.trailingAnchor.constraint(equalTo: button.leadingAnchor, constant: -12),
            textField.heightAnchor.constraint(equalToConstant: 36),
            
            button.trailingAnchor.constraint(equalTo: visualEffectView.trailingAnchor, constant: -16),
            button.centerYAnchor.constraint(equalTo: visualEffectView.centerYAnchor),
            button.widthAnchor.constraint(equalToConstant: 60),
            button.heightAnchor.constraint(equalToConstant: 36)
        ])
        
        // 创建无边框窗口（使用 HUD 面板样式，可以接收键盘事件）
        let window = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 70),
            styleMask: [.borderless, .closable],
            backing: .buffered,
            defer: false
        )
        
        window.contentView = visualEffectView
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.delegate = self
        window.isReleasedWhenClosed = false
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        
        window.center()
        
        self.window = window
        self.textField = textField
    }
    
    @objc private func sendMessage() {
        guard let text = textField?.stringValue.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else {
            // 如果没有内容，隐藏窗口
            hide()
            return
        }
        onSendCallback?(text)
        textField?.stringValue = ""
        hide()
    }
    
    // MARK: - NSWindowDelegate
    
    func windowDidBecomeKey(_ notification: Notification) {
        // 窗口成为 key window 时自动设置焦点
        attemptFocus()
    }
    
    func windowDidBecomeMain(_ notification: Notification) {
        // 窗口成为 main window 时设置焦点
        attemptFocus()
    }
    
    func windowWillClose(_ notification: Notification) {
        focusWorkItem?.cancel()
    }
}

// MARK: - FocusAwareTextField

/// 自定义文本框，更好地处理焦点事件
@MainActor
class FocusAwareTextField: NSTextField {
    
    override var acceptsFirstResponder: Bool {
        return true
    }
    
    override func becomeFirstResponder() -> Bool {
        let success = super.becomeFirstResponder()
        if success {
            // 成为第一响应者时选中所有文本（方便替换）
            DispatchQueue.main.async {
                if let editor = self.currentEditor() as? NSTextView {
                    editor.selectAll(nil)
                }
            }
        }
        return success
    }
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        // 当视图移动到窗口时，如果窗口已经是 key window，尝试获得焦点
        if window?.isKeyWindow == true {
            DispatchQueue.main.async {
                self.window?.makeFirstResponder(self)
            }
        }
    }
}
