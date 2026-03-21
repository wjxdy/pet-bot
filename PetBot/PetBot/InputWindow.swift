// InputWindow.swift
// 输入框窗口控制器 - 使用原生 AppKit 确保可输入

import SwiftUI
import AppKit

@MainActor
class InputWindowController: NSObject, NSTextFieldDelegate {
    static let shared = InputWindowController()
    
    private var window: NSPanel?
    private var textField: NSTextField?
    private var agentManager: AgentManager?
    private var onSendCallback: ((String) -> Void)?
    
    private let positionKey = "inputWindowPositionV5"
    
    var isVisible: Bool {
        return window?.isVisible ?? false
    }
    
    func show(agentManager: AgentManager, onSend: @escaping (String) -> Void) {
        self.agentManager = agentManager
        self.onSendCallback = onSend
        
        if window == nil {
            createWindow()
        }
        
        // 每次显示时更新 placeholder
        updatePlaceholder()
        
        restorePosition()
        
        // 关键：激活应用
        NSApp.activate(ignoringOtherApps: true)
        
        // 显示窗口
        window?.makeKeyAndOrderFront(nil)
        
        // 关键：确保窗口成为 key window 后再设置第一响应者
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            guard let self = self, let window = self.window else { return }
            window.makeKey()
            if let textField = self.textField {
                window.makeFirstResponder(textField)
                textField.becomeFirstResponder()
            }
        }
    }
    
    func hide() {
        savePosition()
        window?.resignKey()
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
        // 创建 NSPanel - 使用 .borderless 而不是 .nonactivatingPanel
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 80),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = true
        // 关键：设置为 false 让 panel 可以成为 key window
        panel.becomesKeyOnlyIfNeeded = false
        
        // 创建内容视图
        let contentView = createContentView()
        panel.contentView = contentView
        
        window = panel
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
        
        // 关键：使用 NSTextField 并配置为可编辑
        let textField = NSTextField(frame: NSRect(x: 16, y: 10, width: 288, height: 28))
        textField.delegate = self
        textField.font = NSFont.systemFont(ofSize: 14)
        textField.textColor = .white
        textField.backgroundColor = .clear
        textField.isBordered = false
        textField.focusRingType = .none
        textField.usesSingleLineMode = true
        textField.lineBreakMode = .byTruncatingTail
        // 关键：确保可编辑
        textField.isEditable = true
        textField.isSelectable = true
        textField.isEnabled = true
        
        // 设置 placeholder
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
    
    // MARK: - NSTextFieldDelegate
    
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        // 检测回车键
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

// Pet 窗口控制器
@MainActor
class PetWindowController: NSObject {
    static let shared = PetWindowController()
    weak var petWindow: NSWindow?
}
