// BubbleWindow.swift
// 独立的气泡窗口 - 像素RPG风格 + 流式输出支持

import Cocoa

@MainActor
class BubbleWindowController: NSObject {
    static let shared = BubbleWindowController()
    
    private var window: NSPanel?
    private var textView: NSTextView?
    private var hideTimer: Timer?
    private var anchorWindowRef: NSWindow?
    
    var isVisible: Bool {
        window?.isVisible ?? false
    }
    
    func show(text: String, anchorWindow: NSWindow?, isStreaming: Bool = false) {
        self.anchorWindowRef = anchorWindow
        
        if window == nil {
            createWindow()
        }
        
        if isStreaming && textView?.string != nil && textView?.string != "(等待回复...)" {
            // 流式输出：追加文本
            textView?.string = text
        } else {
            // 普通输出：直接设置文本
            textView?.string = text.isEmpty ? "(等待回复...)" : text
        }
        
        // 自适应高度
        adjustWindowSize(for: textView?.string ?? "")
        
        // 位置计算
        positionNearAnchor(anchorWindow)
        
        // 显示窗口
        window?.orderFront(nil)
        window?.alphaValue = 0.0
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            window?.animator().alphaValue = 1.0
        }
        
        resetHideTimer()
    }
    
    func hide() {
        guard let window = window, window.isVisible else { return }
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.1
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
                self?.hide()
            }
        }
    }
    
    private var scrollView: NSScrollView?
    
    private func createWindow() {
        let window = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 280, height: 120),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isMovableByWindowBackground = true
        
        // 创建像素风格背景
        let pixelView = PixelBubbleView(frame: NSRect(x: 0, y: 0, width: 280, height: 120))
        
        // 创建滚动视图
        let scrollView = NSScrollView(frame: NSRect(x: 16, y: 16, width: 248, height: 88))
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.backgroundColor = .clear
        scrollView.drawsBackground = false
        scrollView.autoresizingMask = [.width, .height]
        
        // 创建文本视图
        let textView = NSTextView(frame: NSRect(x: 0, y: 0, width: 248, height: 88))
        textView.isEditable = false
        textView.isSelectable = true
        textView.backgroundColor = .clear
        textView.textColor = .black
        textView.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .medium)
        textView.textContainer?.lineFragmentPadding = 0
        textView.textContainerInset = NSSize(width: 4, height: 4)
        textView.autoresizingMask = [.width]
        
        scrollView.documentView = textView
        pixelView.addSubview(scrollView)
        window.contentView = pixelView
        
        self.window = window
        self.scrollView = scrollView
        self.textView = textView
    }
    
    private func adjustWindowSize(for text: String) {
        guard let window = window, let textView = textView, let scrollView = scrollView else { return }
        
        // 计算文本高度
        let maxWidth: CGFloat = 248
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 13, weight: .medium)
        ]
        let attributedText = NSAttributedString(string: text, attributes: attributes)
        let textRect = attributedText.boundingRect(
            with: NSSize(width: maxWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading]
        )
        
        // 计算所需高度（包含内边距）
        let minHeight: CGFloat = 80
        let maxHeight: CGFloat = 400
        let contentPadding: CGFloat = 32 // 上下内边距各 16
        let desiredContentHeight = textRect.height + 20 // 额外间距
        
        // 确定最终窗口高度（限制在 min ~ max 之间）
        let windowHeight = max(minHeight, min(maxHeight, desiredContentHeight + contentPadding))
        let contentHeight = windowHeight - contentPadding
        
        // 获取当前窗口位置（在调整前记录底部位置）
        let currentFrame = window.frame
        let bottomY = currentFrame.origin.y + currentFrame.height
        
        // 计算新位置（保持底部不变，向上扩展）
        let newFrame = NSRect(
            x: currentFrame.origin.x,
            y: bottomY - windowHeight,
            width: 280,
            height: windowHeight
        )
        
        // 动画设置新窗口大小
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window.animator().setFrame(newFrame, display: true)
        }
        
        // 更新滚动视图大小
        scrollView.frame = NSRect(x: 16, y: 16, width: 248, height: contentHeight)
        
        // 更新文本视图大小（允许内容超出以便滚动）
        let textHeight = max(desiredContentHeight, contentHeight)
        textView.frame = NSRect(x: 0, y: 0, width: 248, height: textHeight)
        
        // 滚动到底部（显示最新内容）
        if textHeight > contentHeight {
            let scrollPoint = NSPoint(x: 0, y: textHeight - contentHeight)
            scrollView.contentView.scroll(to: scrollPoint)
            scrollView.reflectScrolledClipView(scrollView.contentView)
        }
        
        // 更新背景视图
        if let pixelView = window.contentView as? PixelBubbleView {
            pixelView.frame = NSRect(x: 0, y: 0, width: 280, height: windowHeight)
            pixelView.needsDisplay = true
        }
    }
    
    private func positionNearAnchor(_ anchorWindow: NSWindow?) {
        guard let window = window else { return }
        
        let anchor = anchorWindow ?? anchorWindowRef
        guard let anchorFrame = anchor?.frame else {
            // 没有锚点窗口，居中显示
            if let screen = NSScreen.main {
                let screenFrame = screen.visibleFrame
                let windowHeight = window.frame.height
                window.setFrameOrigin(NSPoint(x: screenFrame.midX - 140, y: screenFrame.midY - windowHeight / 2))
            }
            return
        }
        
        let offsetX = CGFloat(AppConfiguration.bubbleOffsetX)
        let offsetY = CGFloat(AppConfiguration.bubbleOffsetY)
        let bubbleWidth: CGFloat = 280
        let bubbleHeight = window.frame.height
        
        // 计算气泡位置：居中于锚点窗口上方
        var x = anchorFrame.midX - (bubbleWidth / 2) + offsetX
        var y = anchorFrame.maxY + 10 + offsetY  // +10 是基础间距
        
        // 屏幕边界检测
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            
            // 右边界
            if x + bubbleWidth > screenFrame.maxX {
                x = screenFrame.maxX - bubbleWidth - 10
            }
            // 左边界
            if x < screenFrame.minX {
                x = screenFrame.minX + 10
            }
            // 上边界 - 如果超出，显示在锚点下方
            if y + bubbleHeight > screenFrame.maxY {
                y = anchorFrame.minY - bubbleHeight - 10 - offsetY
            }
            // 下边界
            if y < screenFrame.minY {
                y = screenFrame.minY + 10
            }
        }
        
        // 设置位置
        window.setFrameOrigin(NSPoint(x: x, y: y))
    }
}

// MARK: - 像素风格气泡视图
class PixelBubbleView: NSView {
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        
        let bounds = self.bounds
        
        let bgColor = CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.95)
        let borderColor = CGColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        let shadowColor = CGColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 0.3)
        
        // 绘制阴影
        context.setFillColor(shadowColor)
        drawPixelRect(context, rect: bounds.insetBy(dx: -2, dy: -2), cornerSize: 4)
        
        // 绘制背景
        context.setFillColor(bgColor)
        drawPixelRect(context, rect: bounds, cornerSize: 4)
        
        // 绘制边框
        context.setStrokeColor(borderColor)
        context.setLineWidth(2)
        drawPixelBorder(context, rect: bounds.insetBy(dx: 1, dy: 1), cornerSize: 4)
        
        // 绘制底部小三角
        drawPixelTriangle(context, at: CGPoint(x: bounds.midX, y: 0), size: 8, color: borderColor)
        
        // 填充三角形内部
        context.setFillColor(bgColor)
        let trianglePath = CGMutablePath()
        trianglePath.move(to: CGPoint(x: bounds.midX, y: -1))
        trianglePath.addLine(to: CGPoint(x: bounds.midX - 6, y: 7))
        trianglePath.addLine(to: CGPoint(x: bounds.midX + 6, y: 7))
        trianglePath.closeSubpath()
        context.addPath(trianglePath)
        context.fillPath()
    }
    
    private func drawPixelRect(_ context: CGContext, rect: CGRect, cornerSize: CGFloat) {
        let path = CGMutablePath()
        let cs = cornerSize
        
        path.move(to: CGPoint(x: rect.minX + cs, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX - cs, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - cs))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + cs))
        path.addLine(to: CGPoint(x: rect.maxX - cs, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + cs, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + cs))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - cs))
        path.addLine(to: CGPoint(x: rect.minX + cs, y: rect.maxY))
        
        context.addPath(path)
        context.fillPath()
    }
    
    private func drawPixelBorder(_ context: CGContext, rect: CGRect, cornerSize: CGFloat) {
        let path = CGMutablePath()
        let cs = cornerSize
        
        path.move(to: CGPoint(x: rect.minX + cs, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX - cs, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - cs))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + cs))
        path.addLine(to: CGPoint(x: rect.maxX - cs, y: rect.minY))
        
        let triangleWidth: CGFloat = 16
        path.addLine(to: CGPoint(x: rect.midX + triangleWidth/2, y: rect.minY))
        path.move(to: CGPoint(x: rect.midX - triangleWidth/2, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + cs, y: rect.minY))
        
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + cs))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - cs))
        path.addLine(to: CGPoint(x: rect.minX + cs, y: rect.maxY))
        
        context.addPath(path)
        context.strokePath()
    }
    
    private func drawPixelTriangle(_ context: CGContext, at point: CGPoint, size: CGFloat, color: CGColor) {
        context.setStrokeColor(color)
        context.setLineWidth(2)
        
        let path = CGMutablePath()
        path.move(to: CGPoint(x: point.x, y: point.y - 2))
        path.addLine(to: CGPoint(x: point.x - size/2 + 1, y: point.y + size - 2))
        path.move(to: CGPoint(x: point.x, y: point.y - 2))
        path.addLine(to: CGPoint(x: point.x + size/2 - 1, y: point.y + size - 2))
        
        context.addPath(path)
        context.strokePath()
    }
}
