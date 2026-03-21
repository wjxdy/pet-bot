// InputWindow.swift
// 输入框窗口控制器 - 使用原生 AppKit 确保可输入

import SwiftUI
import AppKit

@MainActor
class InputWindowController: NSObject {
    static let shared = InputWindowController()
    
    private var window: NSPanel?
    private var textView: NSTextView?
    private var placeholderLabel: NSTextField?
    private var agentManager: AgentManager?
    private var onSendCallback: ((String) -> Void)?
    
    private let positionKey = "inputWindowPositionV4"
    
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
        
        // 延迟一点再设置第一响应者，确保窗口已准备好
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.textView?.window?.makeFirstResponder(self?.textView)
        }
    }
    
    func hide() {
        savePosition()
        window?.orderOut(nil)
        textView?.string = ""
        placeholderLabel?.isHidden = false
    }
    
    func close() {
        savePosition()
        window?.close()
        window = nil
        textView = nil
        placeholderLabel = nil
    }
    
    private func createWindow() {
        // 创建 NSPanel
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
        panel.becomesKeyOnlyIfNeeded = false
        
        // 创建内容视图
        let contentView = createContentView()
        panel.contentView = contentView
        
        window = panel
    }
    
    private func createContentView() -> NSView {
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 80))
        
        // 背景 - 增加不透明度到 40%
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
        
        // 输入框背景 - 增加不透明度到 60%
        let inputBg = NSView(frame: NSRect(x: 0, y: 0, width: 320, height: 48))
        inputBg.wantsLayer = true
        inputBg.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.60).cgColor
        inputBg.layer?.cornerRadius = 24
        inputContainer.addSubview(inputBg)
        
        // 使用 NSScrollView + NSTextView 确保可编辑
        let scrollView = NSScrollView(frame: NSRect(x: 16, y: 10, width: 288, height: 28))
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.backgroundColor = .clear
        
        let textView = NSTextView(frame: NSRect(x: 0, y: 0, width: 288, height: 28))
        textView.isEditable = true
        textView.isSelectable = true
        textView.isRichText = false
        textView.font = NSFont.systemFont(ofSize: 14)
        textView.textColor = .white
        textView.backgroundColor = .clear
        textView.insertionPointColor = .white
        textView.focusRingType = .none
        textView.delegate = self
        
        scrollView.documentView = textView
        inputBg.addSubview(scrollView)
        self.textView = textView
        
        // Placeholder 标签
        let placeholder = NSTextField(labelWithString: "给 Agent 发送消息...")
        placeholder.frame = NSRect(x: 20, y: 14, width: 280, height: 20)
        placeholder.font = NSFont.systemFont(ofSize: 14)
        placeholder.textColor = NSColor.white.withAlphaComponent(0.6)
        placeholder.backgroundColor = .clear
        placeholder.isBordered = false
        placeholder.isSelectable = false
        inputBg.addSubview(placeholder)
        self.placeholderLabel = placeholder
        
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
    
    @objc private func sendButtonClicked() {
        let text = textView?.string.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !text.isEmpty else { return }
        onSendCallback?(text)
        textView?.string = ""
        placeholderLabel?.isHidden = false
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

// MARK: - NSTextViewDelegate
extension InputWindowController: NSTextViewDelegate {
    func textDidChange(_ notification: Notification) {
        guard let textView = notification.object as? NSTextView else { return }
        placeholderLabel?.isHidden = !textView.string.isEmpty
    }
    
    func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        // 检测回车键
        if commandSelector == #selector(NSResponder.insertNewline(_:)) {
            let text = textView.string.trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty {
                onSendCallback?(text)
                textView.string = ""
                placeholderLabel?.isHidden = false
                hide()
            }
            return true
        }
        return false
    }
}

// Pet 窗口控制器
@MainActor
class PetWindowController: NSObject {
    static let shared = PetWindowController()
    weak var petWindow: NSWindow?
}
