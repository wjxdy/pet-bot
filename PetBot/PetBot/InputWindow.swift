// InputWindow.swift
// 输入框窗口控制器 - 使用原生 AppKit 确保可输入

import SwiftUI
import AppKit

@MainActor
class InputWindowController: NSObject, NSTextFieldDelegate {
    static let shared = InputWindowController()
    
    private var window: NSWindow?
    private var textField: NSTextField?
    private var agentManager: AgentManager?
    private var onSendCallback: ((String) -> Void)?
    
    private let positionKey = "inputWindowPositionV6"
    
    var isVisible: Bool {
        return window?.isVisible ?? false
    }
    
    func show(agentManager: AgentManager, onSend: @escaping (String) -> Void) {
        self.agentManager = agentManager
        self.onSendCallback = onSend
        
        if window == nil {
            createWindow()
        }
        
        updatePlaceholder()
        restorePosition()
        
        guard let window = window else { return }
        
        // 关键：先激活应用
        NSApp.activate(ignoringOtherApps: true)
        
        // 显示窗口并确保它成为 key window
        window.makeKeyAndOrderFront(nil)
        
        // 强制让窗口成为第一响应者
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let window = self.window, let textField = self.textField else { return }
            
            // 关键步骤：确保窗口是 key window
            if !window.isKeyWindow {
                window.makeKey()
            }
            
            // 设置第一响应者
            window.makeFirstResponder(textField)
            
            // 额外：确保 text field 是 editable 的
            textField.isEditable = true
            textField.isSelectable = true
            textField.isEnabled = true
            
            // 刷新
            textField.needsDisplay = true
            textField.window?.update()
        }
    }
    
    func hide() {
        savePosition()
        window?.orderOut(nil)
        textField?.stringValue = ""
    }
    
    func close() {
        savePosition()
        window?.close()
        window = nil
        textField = nil
    }
    
    private func updatePlaceholder() {
        guard let textField = textField else { return }
        let placeholderAttrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor.white.withAlphaComponent(0.5),
            .font: NSFont.systemFont(ofSize: 14)
        ]
        textField.placeholderAttributedString = NSAttributedString(
            string: "给 \(agentManager?.currentAgent.name ?? "Agent") 发送消息...",
            attributes: placeholderAttrs
        )
    }
    
    private func createWindow() {
        // 关键：使用 NSWindow 而不是 NSPanel，确保可以正常接收输入
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 80),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isMovableByWindowBackground = true
        
        // 关键：接受鼠标事件
        window.ignoresMouseEvents = false
        
        // 创建内容视图
        let contentView = createContentView()
        window.contentView = contentView
        
        self.window = window
    }
    
    private func createContentView() -> NSView {
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 80))
        
        // 背景 - 40% 不透明
        let background = NSView(frame: container.bounds)
        background.wantsLayer = true
        background.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.40).cgColor
        background.layer?.cornerRadius = 20
        background.layer?.shadowColor = NSColor.black.cgColor
        background.layer?.shadowOpacity = 0.3
        background.layer?.shadowRadius = 20
        background.layer?.shadowOffset = CGSize(width: 0, height: 8)
        container.addSubview(background)
        
        // 输入区域容器
        let inputContainer = NSView(frame: NSRect(x: 16, y: 16, width: 368, height: 48))
        background.addSubview(inputContainer)
        
        // 输入框背景 - 60% 不透明
        let inputBg = NSView(frame: NSRect(x: 0, y: 0, width: 320, height: 48))
        inputBg.wantsLayer = true
        inputBg.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.60).cgColor
        inputBg.layer?.cornerRadius = 24
        inputContainer.addSubview(inputBg)
        
        // 关键：创建一个可以接收点击的容器视图
        let clickHandler = ClickableView(frame: NSRect(x: 0, y: 0, width: 320, height: 48))
        clickHandler.onClick = { [weak self] in
            self?.focusTextField()
        }
        inputBg.addSubview(clickHandler)
        
        // 创建 NSTextField
        let textField = NSTextField(frame: NSRect(x: 16, y: 10, width: 288, height: 28))
        textField.delegate = self
        textField.font = NSFont.systemFont(ofSize: 14)
        textField.textColor = .white
        textField.backgroundColor = .clear
        textField.isBordered = false
        textField.focusRingType = .none
        textField.usesSingleLineMode = true
        textField.lineBreakMode = .byTruncatingTail
        textField.isEditable = true
        textField.isSelectable = true
        textField.isEnabled = true
        
        // 占位符
        let placeholderAttrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor.white.withAlphaComponent(0.5),
            .font: NSFont.systemFont(ofSize: 14)
        ]
        textField.placeholderAttributedString = NSAttributedString(
            string: "发送消息...",
            attributes: placeholderAttrs
        )
        
        inputBg.addSubview(textField)
        self.textField = textField
        
        // 发送按钮
        let sendButton = NSButton(frame: NSRect(x: 332, y: 6, width: 36, height: 36))
        sendButton.title = ""
        sendButton.image = NSImage(systemSymbolName: "arrow.up", accessibilityDescription: nil)
        sendButton.bezelStyle = .circular
        sendButton.wantsLayer = true
        sendButton.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.5).cgColor
        sendButton.contentTintColor = .white
        sendButton.target = self
        sendButton.action = #selector(sendButtonClicked)
        inputContainer.addSubview(sendButton)
        
        return container
    }
    
    private func focusTextField() {
        guard let window = window, let textField = textField else { return }
        window.makeKey()
        window.makeFirstResponder(textField)
        textField.becomeFirstResponder()
    }
    
    // MARK: - NSTextFieldDelegate
    
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(NSResponder.insertNewline(_:)) {
            sendButtonClicked()
            return true
        }
        return false
    }
    
    @objc private func sendButtonClicked() {
        guard let textField = textField else { return }
        let text = textField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        onSendCallback?(text)
        textField.stringValue = ""
        hide()
    }
    
    private func savePosition() {
        guard let win = window else { return }
        let frame = win.frame
        UserDefaults.standard.set(["x": frame.origin.x, "y": frame.origin.y], forKey: positionKey)
    }
    
    private func restorePosition() {
        guard let win = window else { return }
        
        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let defaultX = screen.midX - 200
        let defaultY = screen.midY - 40
        
        if let pos = UserDefaults.standard.dictionary(forKey: positionKey) as? [String: Double],
           let x = pos["x"], let y = pos["y"] {
            win.setFrameOrigin(NSPoint(x: x, y: y))
        } else {
            win.setFrameOrigin(NSPoint(x: defaultX, y: defaultY))
        }
    }
}

// 可点击视图 - 用于捕获点击事件
class ClickableView: NSView {
    var onClick: (() -> Void)?
    
    override func mouseDown(with event: NSEvent) {
        onClick?()
    }
}

// Pet 窗口控制器
@MainActor
class PetWindowController: NSObject {
    static let shared = PetWindowController()
    weak var petWindow: NSWindow?
}
