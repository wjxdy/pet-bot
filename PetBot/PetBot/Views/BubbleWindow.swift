// BubbleWindow.swift
// 独立的气泡窗口 - 简化版，使用 AppKit

import Cocoa

@MainActor
class BubbleWindowController: NSObject {
    static let shared = BubbleWindowController()
    
    private var window: NSPanel?
    private var textView: NSTextView?
    private var hideTimer: Timer?
    private var anchorWindowRef: NSWindow?
    private let cornerRadius: CGFloat = 16
    
    var isVisible: Bool {
        window?.isVisible ?? false
    }
    
    func show(text: String, anchorWindow: NSWindow?) {
        self.anchorWindowRef = anchorWindow
        
        if window == nil {
            createWindow()
        }
        
        // 更新文本
        textView?.string = text.isEmpty ? "(等待回复...)" : text
        
        // 位置计算
        positionNearAnchor(anchorWindow)
        
        // 显示窗口
        window?.orderFront(nil)
        window?.alphaValue = 0.0
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            window?.animator().alphaValue = 1.0
        }
        
        resetHideTimer()
        print("[PetBot] 气泡显示: \(text.prefix(30))...")
    }
    
    func hide() {
        guard let window = window, window.isVisible else { return }
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            window.animator().alphaValue = 0.0
        } completionHandler: { [weak self] in
            Task { @MainActor in
                self?.window?.orderOut(nil)
            }
        }
        
        hideTimer?.invalidate()
        hideTimer = nil
    }
    
    func close() {
        window?.close()
        window = nil
        anchorWindowRef = nil
        hideTimer?.invalidate()
        hideTimer = nil
    }
    
    private func resetHideTimer() {
        hideTimer?.invalidate()
        
        let seconds = AppConfiguration.bubbleAutoHideSeconds
        guard seconds > 0 else { return }
        
        hideTimer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false) { [weak self] _ in
            Task { @MainActor in
                print("[PetBot] 气泡 \(Int(seconds)) 秒无新消息，自动隐藏")
                self?.hide()
            }
        }
    }
    
    private func createWindow() {
        // 创建窗口
        let window = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 180),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isMovableByWindowBackground = true
        
        // 创建视觉特效背景
        let visualEffectView = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: 300, height: 180))
        visualEffectView.material = .popover
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.state = .active
        visualEffectView.wantsLayer = true
        visualEffectView.layer?.cornerRadius = cornerRadius
        visualEffectView.layer?.masksToBounds = true
        
        // 关闭按钮
        let closeButton = NSButton(frame: NSRect(x: 270, y: 150, width: 24, height: 24))
        closeButton.title = ""
        closeButton.image = NSImage(systemSymbolName: "xmark.circle.fill", accessibilityDescription: nil)
        closeButton.contentTintColor = .white.withAlphaComponent(0.7)
        closeButton.isBordered = false
        closeButton.target = self
        closeButton.action = #selector(closeClicked)
        closeButton.autoresizingMask = [.minXMargin, .maxYMargin]
        
        // 创建文本视图
        let textContainer = NSTextContainer(size: NSSize(width: 260, height: CGFloat.greatestFiniteMagnitude))
        let layoutManager = NSLayoutManager()
        let textStorage = NSTextStorage()
        
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        
        let textView = NSTextView(frame: NSRect(x: 20, y: 20, width: 260, height: 130), textContainer: textContainer)
        textView.isEditable = false
        textView.isSelectable = true
        textView.backgroundColor = .clear
        textView.textColor = .white
        textView.font = NSFont.systemFont(ofSize: 14)
        textView.autoresizingMask = [.width, .height]
        textView.textContainerInset = NSSize(width: 0, height: 0)
        
        // 添加视图
        visualEffectView.addSubview(textView)
        visualEffectView.addSubview(closeButton)
        window.contentView = visualEffectView
        
        self.window = window
        self.textView = textView
    }
    
    @objc private func closeClicked() {
        hide()
    }
    
    private func positionNearAnchor(_ anchorWindow: NSWindow?) {
        guard let window = window else { return }
        
        let anchor = anchorWindow ?? anchorWindowRef
        guard let anchorFrame = anchor?.frame else {
            if let screen = NSScreen.main {
                let screenFrame = screen.visibleFrame
                window.setFrameOrigin(NSPoint(x: screenFrame.midX - 150, y: screenFrame.midY - 90))
            }
            return
        }
        
        let offsetX = AppConfiguration.bubbleOffsetX
        let offsetY = AppConfiguration.bubbleOffsetY
        let bubbleWidth: CGFloat = 300
        let bubbleHeight: CGFloat = 180
        
        var x = anchorFrame.midX - (bubbleWidth / 2) + offsetX
        var y = anchorFrame.maxY + offsetY
        
        if let screen = anchorWindow?.screen ?? NSScreen.main {
            let screenFrame = screen.visibleFrame
            if x + bubbleWidth > screenFrame.maxX {
                x = screenFrame.maxX - bubbleWidth - 10
            }
            if x < screenFrame.minX {
                x = screenFrame.minX + 10
            }
            if y + bubbleHeight > screenFrame.maxY {
                y = anchorFrame.minY - bubbleHeight - offsetY
            }
        }
        
        window.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
