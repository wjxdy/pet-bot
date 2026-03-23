// BubbleWindow.swift
// 独立的气泡窗口 - 流式输出 + 向上动态扩展

import Cocoa

@MainActor
class BubbleWindowController: NSObject {
    static let shared = BubbleWindowController()
    
    private var window: NSPanel?
    private var streamingView: StreamingBubbleView?
    private var hideTimer: Timer?
    private var anchorWindowRef: NSWindow?
    private var currentText: String = ""
    private var isStreaming: Bool = false
    
    // 最小和最大高度
    private let minHeight: CGFloat = 60
    private let maxHeight: CGFloat = 300
    private let defaultWidth: CGFloat = 280
    
    var isVisible: Bool {
        window?.isVisible ?? false
    }
    
    /// 开始流式输出
    func startStreaming(anchorWindow: NSWindow?) {
        self.anchorWindowRef = anchorWindow
        self.isStreaming = true
        self.currentText = ""
        
        if window == nil {
            createWindow()
        }
        
        // 先定位窗口（使用最小高度）
        positionWindowAtBottom(anchorWindow: anchorWindow, height: minHeight)
        
        streamingView?.startStreaming()
        showWindow()
    }
    
    /// 追加流式文本
    func appendStreamingText(_ text: String) {
        guard isStreaming else { return }
        
        currentText += text
        streamingView?.appendText(text)
        
        // 动态调整高度（保持底部固定，向上扩展）
        streamingView?.getContentHeight { [weak self] height in
            self?.adjustWindowHeightUpward(height)
        }
    }
    
    /// 结束流式输出
    func endStreaming() {
        isStreaming = false
        streamingView?.endStreaming()
        resetHideTimer()
    }
    
    /// 显示普通文本（非流式）
    func show(text: String, anchorWindow: NSWindow?) {
        self.anchorWindowRef = anchorWindow
        self.isStreaming = false
        self.currentText = text
        
        if window == nil {
            createWindow()
        }
        
        streamingView?.setText(text)
        
        // 先计算高度，再定位（保持底部固定）
        streamingView?.getContentHeight { [weak self] height in
            guard let self = self else { return }
            let targetHeight = max(self.minHeight, min(self.maxHeight, height))
            self.positionWindowAtBottom(anchorWindow: anchorWindow, height: targetHeight)
        }
        
        showWindow()
        resetHideTimer()
    }
    
    private func showWindow() {
        window?.orderFront(nil)
        window?.alphaValue = 0.0
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            window?.animator().alphaValue = 1.0
        }
    }
    
    /// 定位窗口，使下边框与 Pet 对齐（从底部向上扩展）
    private func positionWindowAtBottom(anchorWindow: NSWindow?, height: CGFloat) {
        guard let window = window, let anchor = anchorWindow ?? anchorWindowRef else { return }
        
        let anchorFrame = anchor.frame
        let offsetX = CGFloat(AppConfiguration.bubbleOffsetX)
        let offsetY = CGFloat(AppConfiguration.bubbleOffsetY)
        
        // 计算 x 位置：Pet 左侧
        var x = anchorFrame.minX - defaultWidth + offsetX
        
        // 计算 y 位置：窗口底部与 Pet 顶部对齐（气泡下边框贴着 Pet 上边框）
        let bottomY = anchorFrame.maxY + offsetY
        
        // 屏幕边界检测
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            
            if x < screenFrame.minX {
                x = screenFrame.minX + 10
            }
            if x + defaultWidth > screenFrame.maxX {
                x = screenFrame.maxX - defaultWidth - 10
            }
            // 如果上方空间不够，显示在 Pet 下方
            if bottomY + height > screenFrame.maxY {
                let yBelow = anchorFrame.minY - height - 10
                window.setFrame(NSRect(x: x, y: yBelow, width: defaultWidth, height: height), display: false)
                return
            }
        }
        
        window.setFrame(NSRect(x: x, y: bottomY, width: defaultWidth, height: height), display: false)
    }
    
    /// 调整窗口高度（向上扩展，保持底部固定）
    private func adjustWindowHeightUpward(_ contentHeight: CGFloat) {
        guard let window = window, let anchor = anchorWindowRef else { return }
        
        let newHeight = max(minHeight, min(maxHeight, contentHeight))
        let anchorFrame = anchor.frame
        let offsetY = CGFloat(AppConfiguration.bubbleOffsetY)
        let bottomY = anchorFrame.maxY + offsetY
        
        // 快速动画调整高度
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.05
            window.animator().setFrame(
                NSRect(x: window.frame.origin.x, y: bottomY, width: defaultWidth, height: newHeight),
                display: true
            )
        }
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
        currentText = ""
        isStreaming = false
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
            contentRect: NSRect(x: 0, y: 0, width: defaultWidth, height: minHeight),
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
        let pixelView = PixelBubbleView(frame: NSRect(x: 0, y: 0, width: defaultWidth, height: minHeight))
        
        // 创建流式文本视图
        let streamingView = StreamingBubbleView(frame: NSRect(x: 16, y: 16, width: defaultWidth - 32, height: minHeight - 32))
        streamingView.autoresizingMask = [.width, .height]
        pixelView.addSubview(streamingView)
        
        window.contentView = pixelView
        
        self.window = window
        self.streamingView = streamingView
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
        
        // 绘制底部小三角（指向Pet，位于底部右侧）
        let triangleX: CGFloat = bounds.maxX - 20
        drawPixelTriangleBottom(context, at: CGPoint(x: triangleX, y: 0), size: 8, color: borderColor)
        
        // 填充三角形内部
        context.setFillColor(bgColor)
        let trianglePath = CGMutablePath()
        trianglePath.move(to: CGPoint(x: triangleX, y: -1))
        trianglePath.addLine(to: CGPoint(x: triangleX - 6, y: 7))
        trianglePath.addLine(to: CGPoint(x: triangleX + 6, y: 7))
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
        
        // 右侧底部留出三角形位置
        let triangleY: CGFloat = 16 + 8
        path.addLine(to: CGPoint(x: rect.maxX, y: triangleY + 8))
        path.move(to: CGPoint(x: rect.maxX, y: triangleY - 8))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + cs))
        
        path.addLine(to: CGPoint(x: rect.maxX - cs, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + cs, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + cs))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - cs))
        path.addLine(to: CGPoint(x: rect.minX + cs, y: rect.maxY))
        
        context.addPath(path)
        context.strokePath()
    }
    
    private func drawPixelTriangleBottom(_ context: CGContext, at point: CGPoint, size: CGFloat, color: CGColor) {
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
