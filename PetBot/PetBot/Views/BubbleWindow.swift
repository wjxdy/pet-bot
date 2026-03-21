// BubbleWindow.swift
// 独立的气泡窗口 - 像素RPG风格

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
    
    func show(text: String, anchorWindow: NSWindow?) {
        self.anchorWindowRef = anchorWindow
        
        if window == nil {
            createWindow()
        }
        
        // 更新文本
        textView?.string = text.isEmpty ? "(等待回复...)" : text
        
        // 自适应高度
        adjustWindowSize(for: text)
        
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
    
    private func createWindow() {
        let window = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 280, height: 120),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false  // 像素风格不需要阴影
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isMovableByWindowBackground = true
        
        // 创建像素风格背景
        let pixelView = PixelBubbleView(frame: NSRect(x: 0, y: 0, width: 280, height: 120))
        
        // 创建文本视图 - 使用像素友好字体
        let textView = NSTextView(frame: NSRect(x: 16, y: 16, width: 248, height: 88))
        textView.isEditable = false
        textView.isSelectable = true
        textView.backgroundColor = .clear
        textView.textColor = .black
        // 使用等宽字体，更有像素感
        textView.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .medium)
        textView.autoresizingMask = [.width, .height]
        textView.textContainer?.lineFragmentPadding = 0
        textView.textContainerInset = NSSize(width: 0, height: 0)
        
        pixelView.addSubview(textView)
        window.contentView = pixelView
        
        self.window = window
        self.textView = textView
    }
    
    private func adjustWindowSize(for text: String) {
        guard let window = window, let textView = textView else { return }
        
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
        
        // 计算所需高度（加上边距）
        let minHeight: CGFloat = 80
        let maxHeight: CGFloat = 200
        let contentHeight = max(minHeight, min(maxHeight, textRect.height + 40))
        
        // 更新窗口大小
        var frame = window.frame
        frame.size.height = contentHeight
        window.setFrame(frame, display: true)
        
        // 更新文本视图大小
        textView.frame = NSRect(x: 16, y: 16, width: 248, height: contentHeight - 32)
        
        // 更新背景视图
        if let pixelView = window.contentView as? PixelBubbleView {
            pixelView.frame = NSRect(x: 0, y: 0, width: 280, height: contentHeight)
            pixelView.needsDisplay = true
        }
    }
    
    private func positionNearAnchor(_ anchorWindow: NSWindow?) {
        guard let window = window else { return }
        
        let anchor = anchorWindow ?? anchorWindowRef
        guard let anchorFrame = anchor?.frame else {
            if let screen = NSScreen.main {
                let screenFrame = screen.visibleFrame
                window.setFrameOrigin(NSPoint(x: screenFrame.midX - 140, y: screenFrame.midY - 60))
            }
            return
        }
        
        let offsetX = AppConfiguration.bubbleOffsetX
        let offsetY = AppConfiguration.bubbleOffsetY
        let bubbleWidth: CGFloat = 280
        let bubbleHeight = window.frame.height
        
        // 默认显示在宠物上方
        var x = anchorFrame.midX - (bubbleWidth / 2) + offsetX
        var y = anchorFrame.maxY + 10 + offsetY
        
        if let screen = anchorWindow?.screen ?? NSScreen.main {
            let screenFrame = screen.visibleFrame
            if x + bubbleWidth > screenFrame.maxX {
                x = screenFrame.maxX - bubbleWidth - 10
            }
            if x < screenFrame.minX {
                x = screenFrame.minX + 10
            }
            if y + bubbleHeight > screenFrame.maxY {
                y = anchorFrame.minY - bubbleHeight - 10 - offsetY
            }
        }
        
        window.setFrameOrigin(NSPoint(x: x, y: y))
    }
}

// MARK: - 像素风格气泡视图
class PixelBubbleView: NSView {
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        
        let bounds = self.bounds
        
        // 像素风格配色 - 经典RPG对话框
        let bgColor = CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.95)  // 纯白背景
        let borderColor = CGColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)  // 黑色边框
        let shadowColor = CGColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 0.3)  // 轻微阴影
        
        // 绘制像素化阴影（偏移2px）
        context.setFillColor(shadowColor)
        drawPixelRect(context, rect: bounds.insetBy(dx: -2, dy: -2), cornerSize: 4)
        
        // 绘制背景
        context.setFillColor(bgColor)
        drawPixelRect(context, rect: bounds, cornerSize: 4)
        
        // 绘制像素边框（2px粗）
        context.setStrokeColor(borderColor)
        context.setLineWidth(2)
        drawPixelBorder(context, rect: bounds.insetBy(dx: 1, dy: 1), cornerSize: 4)
        
        // 绘制底部小三角（指向宠物）
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
    
    // 绘制像素化圆角矩形
    private func drawPixelRect(_ context: CGContext, rect: CGRect, cornerSize: CGFloat) {
        let path = CGMutablePath()
        
        // 使用阶梯式圆角（像素风格）
        let cs = cornerSize
        
        // 从左上角开始
        path.move(to: CGPoint(x: rect.minX + cs, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX - cs, y: rect.maxY))
        // 右上角
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - cs))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + cs))
        // 右下角
        path.addLine(to: CGPoint(x: rect.maxX - cs, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + cs, y: rect.minY))
        // 左下角
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + cs))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - cs))
        // 回到起点
        path.addLine(to: CGPoint(x: rect.minX + cs, y: rect.maxY))
        
        context.addPath(path)
        context.fillPath()
    }
    
    // 绘制像素化边框
    private func drawPixelBorder(_ context: CGContext, rect: CGRect, cornerSize: CGFloat) {
        let path = CGMutablePath()
        let cs = cornerSize
        
        // 外框路径（不包括底部三角形区域）
        path.move(to: CGPoint(x: rect.minX + cs, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX - cs, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - cs))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + cs))
        path.addLine(to: CGPoint(x: rect.maxX - cs, y: rect.minY))
        
        // 底部边缘（留出三角形缺口）
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
    
    // 绘制像素三角形
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
