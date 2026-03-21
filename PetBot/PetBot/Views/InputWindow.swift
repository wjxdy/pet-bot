// InputWindow.swift
// 输入窗口 - 优化样式

import Cocoa

@MainActor
class InputWindowController: NSObject, NSWindowDelegate {
    static let shared = InputWindowController()
    
    private var window: NSWindow?
    private var textField: NSTextField?
    private var onSendCallback: ((String) -> Void)?
    private var focusWorkItem: DispatchWorkItem?
    private let cornerRadius: CGFloat = 16
    
    var isVisible: Bool {
        window?.isVisible ?? false
    }
    
    func show(viewModel: AgentViewModel, onSend: @escaping (String) -> Void) {
        self.onSendCallback = onSend
        focusWorkItem?.cancel()
        
        if window == nil {
            createWindow()
        }
        
        guard let window = window, let textField = textField else { return }
        
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        textField.stringValue = ""
        
        setFocusToTextField()
        
        focusWorkItem = DispatchWorkItem { [weak self] in
            self?.setFocusToTextField()
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
    
    private func setFocusToTextField() {
        guard let window = window, let textField = textField else { return }
        if !window.isKeyWindow {
            window.makeKeyAndOrderFront(nil)
        }
        window.makeFirstResponder(textField)
        textField.becomeFirstResponder()
    }
    
    private func createWindow() {
        // 创建窗口
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 56),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        // 隐藏标题栏
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.standardWindowButton(.closeButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        
        // 创建容器视图
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 440, height: 56))
        container.wantsLayer = true
        container.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        container.layer?.cornerRadius = cornerRadius
        container.layer?.masksToBounds = true
        
        // 阴影
        container.layer?.shadowColor = NSColor.black.cgColor
        container.layer?.shadowOpacity = 0.15
        container.layer?.shadowRadius = 20
        container.layer?.shadowOffset = CGSize(width: 0, height: 8)
        
        // 创建文本框 - 扁平设计
        let textField = NSTextField()
        textField.placeholderString = "输入消息给 Agent..."
        textField.font = NSFont.systemFont(ofSize: 15)
        textField.isEditable = true
        textField.isSelectable = true
        textField.isEnabled = true
        textField.bezelStyle = .roundedBezel
        textField.focusRingType = .default
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.target = self
        textField.action = #selector(sendMessage)
        
        // 创建发送按钮 - 胶囊形状
        let button = NSButton()
        button.title = "发送"
        button.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        button.bezelStyle = .texturedRounded
        button.keyEquivalent = "\r"
        button.target = self
        button.action = #selector(sendMessage)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        // 添加视图
        container.addSubview(textField)
        container.addSubview(button)
        window.contentView = container
        
        // 约束
        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            textField.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            textField.trailingAnchor.constraint(equalTo: button.leadingAnchor, constant: -12),
            textField.heightAnchor.constraint(equalToConstant: 32),
            
            button.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            button.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            button.widthAnchor.constraint(equalToConstant: 64),
            button.heightAnchor.constraint(equalToConstant: 32)
        ])
        
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.delegate = self
        window.isReleasedWhenClosed = false
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
    
    func windowDidBecomeKey(_ notification: Notification) {
        setFocusToTextField()
    }
    
    func windowWillClose(_ notification: Notification) {
        focusWorkItem?.cancel()
    }
}
