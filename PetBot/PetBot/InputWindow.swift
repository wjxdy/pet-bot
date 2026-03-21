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
        // 创建 NSPanel - 专门用于输入
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 90),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = true
        
        // 创建内容视图
        let contentView = createContentView()
        panel.contentView = contentView
        
        window = panel
    }
    
    private func createContentView() -> NSView {
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 320, height: 90))
        
        // 背景
        let background = NSView(frame: container.bounds)
        background.wantsLayer = true
        background.layer?.backgroundColor = NSColor.white.cgColor
        background.layer?.cornerRadius = 12
        background.layer?.shadowColor = NSColor.black.cgColor
        background.layer?.shadowOpacity = 0.2
        background.layer?.shadowRadius = 20
        background.layer?.shadowOffset = CGSize(width: 0, height: 8)
        container.addSubview(background)
        
        // Agent 颜色
        let color = agentManager?.currentAgent.color ?? .blue
        let nsColor = NSColor(color)
        
        // 顶部条 - 标题和关闭按钮
        let titleBar = NSView(frame: NSRect(x: 0, y: 56, width: 320, height: 34))
        background.addSubview(titleBar)
        
        // 颜色指示点
        let colorDot = NSView(frame: NSRect(x: 12, y: 13, width: 8, height: 8))
        colorDot.wantsLayer = true
        colorDot.layer?.backgroundColor = nsColor.cgColor
        colorDot.layer?.cornerRadius = 4
        titleBar.addSubview(colorDot)
        
        // 标题
        let titleLabel = NSTextField(labelWithString: agentManager?.currentAgent.name ?? "Agent")
        titleLabel.frame = NSRect(x: 26, y: 8, width: 100, height: 18)
        titleLabel.font = NSFont.systemFont(ofSize: 11)
        titleLabel.textColor = .secondaryLabelColor
        titleBar.addSubview(titleLabel)
        
        // 关闭按钮
        let closeButton = NSButton(frame: NSRect(x: 286, y: 6, width: 22, height: 22))
        closeButton.title = ""
        closeButton.image = NSImage(systemSymbolName: "xmark", accessibilityDescription: nil)
        closeButton.bezelStyle = .circular
        closeButton.target = self
        closeButton.action = #selector(closeButtonClicked)
        titleBar.addSubview(closeButton)
        
        // 分隔线
        let separator = NSView(frame: NSRect(x: 10, y: 55, width: 300, height: 1))
        separator.wantsLayer = true
        separator.layer?.backgroundColor = NSColor.separatorColor.cgColor
        background.addSubview(separator)
        
        // 输入框容器
        let inputContainer = NSView(frame: NSRect(x: 10, y: 10, width: 300, height: 38))
        background.addSubview(inputContainer)
        
        // 输入框背景
        let inputBackground = NSView(frame: NSRect(x: 0, y: 0, width: 260, height: 38))
        inputBackground.wantsLayer = true
        inputBackground.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        inputBackground.layer?.cornerRadius = 8
        inputContainer.addSubview(inputBackground)
        
        // 文本输入框 - 使用 NSTextField 确保可输入
        let textField = NSTextField(frame: NSRect(x: 8, y: 6, width: 244, height: 26))
        textField.placeholderString = "输入消息..."
        textField.font = NSFont.systemFont(ofSize: 13)
        textField.isBordered = false
        textField.backgroundColor = .clear
        textField.focusRingType = .none
        textField.target = self
        textField.action = #selector(sendButtonClicked)
        inputBackground.addSubview(textField)
        self.textField = textField
        
        // 发送按钮
        let sendButton = NSButton(frame: NSRect(x: 270, y: 3, width: 32, height: 32))
        sendButton.title = ""
        sendButton.image = NSImage(systemSymbolName: "arrow.up", accessibilityDescription: nil)
        sendButton.bezelStyle = .circular
        sendButton.wantsLayer = true
        sendButton.layer?.backgroundColor = nsColor.cgColor
        sendButton.contentTintColor = .white
        sendButton.target = self
        sendButton.action = #selector(sendButtonClicked)
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
        let defaultX = screen.midX - 160
        let defaultY = screen.midY - 45
        
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
