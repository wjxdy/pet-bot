// InputWindow.swift
// 输入框窗口控制器 - 使用原生 AppKit 确保可输入

import SwiftUI
import AppKit

@MainActor
class InputWindowController: NSObject {
    static let shared = InputWindowController()
    
    private var window: NSPanel?
    private var textField: NSTextField?
    private var agentManager: AgentManager?
    private var onSendCallback: ((String) -> Void)?
    
    private let positionKey = "inputWindowPositionV3"
    
    var isVisible: Bool {
        return window?.isVisible ?? false
    }
    
    func show(agentManager: AgentManager, onSend: @escaping (String) -> Void) {
        self.agentManager = agentManager
        self.onSendCallback = onSend
        
        if window == nil {
            createWindow()
        }
        
        restorePosition()
        
        // 显示窗口
        window?.makeKeyAndOrderFront(nil)
        
        // 激活应用，确保输入有效
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKey()
        textField?.becomeFirstResponder()
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
    
    private func createWindow() {
        // 创建 NSPanel - 移除 nonactivatingPanel 以支持输入
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
        panel.becomesKeyOnlyIfNeeded = false  // 确保可以成为 key window
        
        // 创建内容视图
        let contentView = createContentView()
        panel.contentView = contentView
        
        window = panel
    }
    
    private func createContentView() -> NSView {
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 80))
        
        // 背景 - 透明+阴影风格
        let background = NSView(frame: container.bounds)
        background.wantsLayer = true
        background.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.15).cgColor
        background.layer?.cornerRadius = 20
        background.layer?.shadowColor = NSColor.black.cgColor
        background.layer?.shadowOpacity = 0.3
        background.layer?.shadowRadius = 20
        background.layer?.shadowOffset = CGSize(width: 0, height: 8)
        container.addSubview(background)
        
        // Agent 颜色
        let color = agentManager?.currentAgent.color ?? .blue
        let nsColor = NSColor(color)
        
        // 输入区域容器
        let inputContainer = NSView(frame: NSRect(x: 16, y: 16, width: 368, height: 48))
        background.addSubview(inputContainer)
        
        // 输入框背景 - 半透明白色
        let inputBorder = NSView(frame: NSRect(x: 0, y: 0, width: 320, height: 48))
        inputBorder.wantsLayer = true
        inputBorder.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.25).cgColor
        inputBorder.layer?.cornerRadius = 24
        inputBorder.layer?.shadowColor = NSColor.black.cgColor
        inputBorder.layer?.shadowOpacity = 0.15
        inputBorder.layer?.shadowRadius = 10
        inputBorder.layer?.shadowOffset = CGSize(width: 0, height: 4)
        inputContainer.addSubview(inputBorder)
        
        // 文本输入框
        let textField = NSTextField(frame: NSRect(x: 16, y: 10, width: 288, height: 28))
        textField.placeholderString = "给 Agent 发送消息..."
        textField.font = NSFont.systemFont(ofSize: 14)
        textField.textColor = .white
        textField.isBordered = false
        textField.backgroundColor = .clear
        textField.focusRingType = .none
        textField.isEditable = true
        textField.isSelectable = true
        textField.target = self
        textField.action = #selector(sendButtonClicked)
        
        // 设置 placeholder 颜色为白色半透明
        let placeholderAttrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor.white.withAlphaComponent(0.6),
            .font: NSFont.systemFont(ofSize: 14)
        ]
        textField.placeholderAttributedString = NSAttributedString(
            string: "给 Agent 发送消息...",
            attributes: placeholderAttrs
        )
        
        inputBorder.addSubview(textField)
        self.textField = textField
        
        // 发送按钮 - 右侧圆形按钮
        let sendButton = NSButton(frame: NSRect(x: 332, y: 6, width: 36, height: 36))
        sendButton.title = ""
        sendButton.image = NSImage(systemSymbolName: "arrow.up", accessibilityDescription: nil)
        sendButton.bezelStyle = .circular
        sendButton.wantsLayer = true
        sendButton.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.3).cgColor
        sendButton.contentTintColor = .white
        sendButton.target = self
        sendButton.action = #selector(sendButtonClicked)
        
        // 按钮阴影
        sendButton.layer?.shadowColor = NSColor.black.cgColor
        sendButton.layer?.shadowOpacity = 0.3
        sendButton.layer?.shadowRadius = 8
        sendButton.layer?.shadowOffset = CGSize(width: 0, height: 2)
        
        inputContainer.addSubview(sendButton)
        
        return container
    }
    
    @objc private func closeButtonClicked() {
        hide()
    }
    
    @objc private func sendButtonClicked() {
        guard let text = textField?.stringValue, !text.isEmpty else { return }
        onSendCallback?(text)
        textField?.stringValue = ""
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
        let defaultX = screen.midX - 200  // 400/2 = 200
        let defaultY = screen.midY - 40   // 80/2 = 40
        
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
