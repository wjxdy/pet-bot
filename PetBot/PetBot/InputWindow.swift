// InputWindow.swift
// 输入框窗口控制器 - 使用原生 AppKit 确保可输入

import SwiftUI
import AppKit

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
        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
            self.window?.makeKeyWindow()
            self.textField?.becomeFirstResponder()
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
    
    private func createWindow() {
        // 创建 NSPanel - 移除 nonactivatingPanel 以支持输入
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 120),
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
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 120))
        
        // 背景 - ChatGPT 风格深色主题
        let background = NSView(frame: container.bounds)
        background.wantsLayer = true
        background.layer?.backgroundColor = NSColor(calibratedWhite: 0.12, alpha: 1.0).cgColor
        background.layer?.cornerRadius = 16
        background.layer?.shadowColor = NSColor.black.cgColor
        background.layer?.shadowOpacity = 0.4
        background.layer?.shadowRadius = 30
        background.layer?.shadowOffset = CGSize(width: 0, height: 10)
        container.addSubview(background)
        
        // Agent 颜色
        let color = agentManager?.currentAgent.color ?? .blue
        let nsColor = NSColor(color)
        
        // 顶部栏 - 标题和关闭按钮
        let titleBar = NSView(frame: NSRect(x: 0, y: 84, width: 400, height: 36))
        background.addSubview(titleBar)
        
        // 颜色指示点
        let colorDot = NSView(frame: NSRect(x: 16, y: 12, width: 8, height: 8))
        colorDot.wantsLayer = true
        colorDot.layer?.backgroundColor = nsColor.cgColor
        colorDot.layer?.cornerRadius = 4
        titleBar.addSubview(colorDot)
        
        // 标题
        let titleLabel = NSTextField(labelWithString: agentManager?.currentAgent.name ?? "Agent")
        titleLabel.frame = NSRect(x: 32, y: 8, width: 150, height: 20)
        titleLabel.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        titleLabel.textColor = .white
        titleBar.addSubview(titleLabel)
        
        // 关闭按钮 - 右上角
        let closeButton = NSButton(frame: NSRect(x: 366, y: 6, width: 24, height: 24))
        closeButton.title = ""
        closeButton.image = NSImage(systemSymbolName: "xmark", accessibilityDescription: nil)
        closeButton.bezelStyle = .circular
        closeButton.contentTintColor = .gray
        closeButton.target = self
        closeButton.action = #selector(closeButtonClicked)
        titleBar.addSubview(closeButton)
        
        // 分隔线
        let separator = NSView(frame: NSRect(x: 16, y: 82, width: 368, height: 1))
        separator.wantsLayer = true
        separator.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.1).cgColor
        background.addSubview(separator)
        
        // 输入区域容器 - ChatGPT 风格
        let inputContainer = NSView(frame: NSRect(x: 16, y: 12, width: 368, height: 60))
        background.addSubview(inputContainer)
        
        // 输入框外边框 - 发光效果
        let inputBorder = NSView(frame: NSRect(x: 0, y: 0, width: 320, height: 44))
        inputBorder.wantsLayer = true
        inputBorder.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.08).cgColor
        inputBorder.layer?.cornerRadius = 12
        inputBorder.layer?.borderWidth = 1
        inputBorder.layer?.borderColor = NSColor.white.withAlphaComponent(0.15).cgColor
        inputContainer.addSubview(inputBorder)
        
        // 文本输入框
        let textField = NSTextField(frame: NSRect(x: 12, y: 8, width: 296, height: 28))
        textField.placeholderString = "给 Agent 发送消息..."
        textField.font = NSFont.systemFont(ofSize: 14)
        textField.textColor = .white
        textField.isBordered = false
        textField.backgroundColor = .clear
        textField.focusRingType = .none
        textField.target = self
        textField.action = #selector(sendButtonClicked)
        
        // 设置 placeholder 颜色为灰色
        let placeholderAttrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor.gray,
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
        sendButton.layer?.backgroundColor = nsColor.cgColor
        sendButton.contentTintColor = .white
        sendButton.target = self
        sendButton.action = #selector(sendButtonClicked)
        
        // 按钮阴影
        sendButton.layer?.shadowColor = nsColor.cgColor
        sendButton.layer?.shadowOpacity = 0.5
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
        let defaultY = screen.midY - 60   // 120/2 = 60
        
        if let pos = UserDefaults.standard.dictionary(forKey: positionKey) as? [String: Double],
           let x = pos["x"], let y = pos["y"] {
            win.setFrameOrigin(NSPoint(x: x, y: y))
        } else {
            win.setFrameOrigin(NSPoint(x: defaultX, y: defaultY))
        }
    }
}

// Pet 窗口控制器
class PetWindowController: NSObject {
    static let shared = PetWindowController()
    weak var petWindow: NSWindow?
}
