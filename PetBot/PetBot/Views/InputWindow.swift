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
        
        // 激活应用并显示窗口
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        
        // 清除输入框
        textField.stringValue = ""
        
        // 多阶段焦点设置
        setFocusToTextField(immediate: true)
        
        // 延迟再次尝试
        focusWorkItem = DispatchWorkItem { [weak self] in
            self?.setFocusToTextField(immediate: false)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: focusWorkItem!)
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
    
    private func setFocusToTextField(immediate: Bool) {
        guard let window = window, let textField = textField else { return }
        
        print("[PetBot] 设置焦点 (immediate: \(immediate))")
        
        // 确保窗口是 key window
        if !window.isKeyWindow {
            window.makeKeyAndOrderFront(nil)
        }
        
        // 使用 performSelector 延迟调用，确保在下一个 run loop
        if immediate {
            textField.perform(#selector(NSView.becomeFirstResponder), with: nil, afterDelay: 0)
        } else {
            // 强制设置第一响应者
            window.makeFirstResponder(textField)
            
            // 如果还没成为第一响应者，再次尝试
            if window.firstResponder !== textField {
                DispatchQueue.main.async {
                    textField.becomeFirstResponder()
                }
            }
        }
    }
    
    private func createWindow() {
        // 使用 titled 窗口以确保键盘事件正常，但隐藏标题栏
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 70),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        // 隐藏标题栏但保留标题功能（用于接收键盘事件）
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.standardWindowButton(.closeButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        
        // 创建视觉特效背景
        let visualEffectView = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: 420, height: 70))
        visualEffectView.material = .hudWindow
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.state = .active
        visualEffectView.wantsLayer = true
        visualEffectView.layer?.cornerRadius = cornerRadius
        visualEffectView.layer?.masksToBounds = true
        
        // 创建文本框
        let textField = FocusAwareTextField()
        textField.placeholderString = "输入消息..."
        textField.font = NSFont.systemFont(ofSize: 15, weight: .medium)
        textField.isEditable = true
        textField.isSelectable = true
        textField.isEnabled = true
        textField.bezelStyle = .roundedBezel
        textField.focusRingType = .default
        textField.backgroundColor = NSColor.white.withAlphaComponent(0.15)
        textField.textColor = .white
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.target = self
        textField.action = #selector(sendMessage)
        
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
            hide()
            return
        }
        onSendCallback?(text)
        textField?.stringValue = ""
        hide()
    }
    
    // MARK: - NSWindowDelegate
    
    func windowDidBecomeKey(_ notification: Notification) {
        print("[PetBot] 窗口成为 key window")
        setFocusToTextField(immediate: false)
    }
    
    func windowWillClose(_ notification: Notification) {
        focusWorkItem?.cancel()
    }
}

// MARK: - FocusAwareTextField

@MainActor
class FocusAwareTextField: NSTextField {
    
    override var acceptsFirstResponder: Bool {
        return true
    }
    
    override func becomeFirstResponder() -> Bool {
        print("[PetBot] textField becomeFirstResponder")
        let success = super.becomeFirstResponder()
        if success {
            // 选中所有文本
            if let editor = self.currentEditor() as? NSTextView {
                editor.selectAll(nil)
            }
        }
        return success
    }
    
    override func mouseDown(with event: NSEvent) {
        // 点击时确保获得焦点
        window?.makeFirstResponder(self)
        super.mouseDown(with: event)
    }
}
