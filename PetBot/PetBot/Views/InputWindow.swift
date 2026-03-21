// InputWindow.swift
// 输入窗口 - 像素RPG风格

import Cocoa

@MainActor
class InputWindowController: NSObject, NSWindowDelegate {
    static let shared = InputWindowController()
    
    private var window: NSWindow?
    private var textField: NSTextField?
    private var onSendCallback: ((String) -> Void)?
    private var focusWorkItem: DispatchWorkItem?
    
    var isVisible: Bool {
        window?.isVisible ?? false
    }
    
    func show(viewModel: AgentViewModel, onSend: @escaping (String) -> Void) {
        self.onSendCallback = onSend
        focusWorkItem?.cancel()
        
        if window == nil {
            createWindow()
        }
        
        guard let window = window, let textField = textField else { return }
        
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        textField.stringValue = ""
        
        setFocusToTextField()
        
        focusWorkItem = DispatchWorkItem { [weak self] in
            self?.setFocusToTextField()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: focusWorkItem!)
    }
    
    func hide() {
        focusWorkItem?.cancel()
        window?.orderOut(nil)
    }
    
    func close() {
        focusWorkItem?.cancel()
        window?.close()
        window = nil
        textField = nil
    }
    
    private func setFocusToTextField() {
        guard let window = window, let textField = textField else { return }
        if !window.isKeyWindow {
            window.makeKeyAndOrderFront(nil)
        }
        window.makeFirstResponder(textField)
        textField.becomeFirstResponder()
    }
    
    private func createWindow() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 60),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        // 隐藏标题栏
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.standardWindowButton(.closeButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        
        // 创建像素风格背景视图
        let pixelView = PixelInputView(frame: NSRect(x: 0, y: 0, width: 400, height: 60))
        
        // 创建文本框 - 像素风格
        let textField = PixelTextField()
        textField.placeholderString = "输入消息..."
        textField.font = NSFont.monospacedSystemFont(ofSize: 14, weight: .medium)
        textField.isEditable = true
        textField.isSelectable = true
        textField.isEnabled = true
        textField.backgroundColor = .clear
        textField.textColor = .white
        textField.focusRingType = .none
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.target = self
        textField.action = #selector(sendMessage)
        
        // 创建像素风格发送按钮
        let button = PixelButton()
        button.title = "▶"
        button.font = NSFont.monospacedSystemFont(ofSize: 16, weight: .bold)
        button.target = self
        button.action = #selector(sendMessage)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        // 添加视图
        pixelView.addSubview(textField)
        pixelView.addSubview(button)
        window.contentView = pixelView
        
        // 约束
        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: pixelView.leadingAnchor, constant: 20),
            textField.centerYAnchor.constraint(equalTo: pixelView.centerYAnchor),
            textField.trailingAnchor.constraint(equalTo: button.leadingAnchor, constant: -12),
            textField.heightAnchor.constraint(equalToConstant: 28),
            
            button.trailingAnchor.constraint(equalTo: pixelView.trailingAnchor, constant: -16),
            button.centerYAnchor.constraint(equalTo: pixelView.centerYAnchor),
            button.widthAnchor.constraint(equalToConstant: 36),
            button.heightAnchor.constraint(equalToConstant: 36)
        ])
        
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.delegate = self
        window.isReleasedWhenClosed = false
        
        // 设置位置（使用配置或居中）
        let configX = AppConfiguration.inputInitialX
        let configY = AppConfiguration.inputInitialY
        
        if configX >= 0 && configY >= 0 {
            // 使用自定义位置
            let windowWidth: CGFloat = 400
            let windowHeight: CGFloat = 60
            window.setFrameOrigin(NSPoint(x: configX - windowWidth/2, y: configY - windowHeight/2))
        } else {
            // 居中显示
            window.center()
        }
        
        self.window = window
        self.textField = textField
    }
    
    @objc private func sendMessage() {
        guard let text = textField?.stringValue.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else {
            hide()
            return
        }
        onSendCallback?(text)
        textField?.stringValue = ""
        hide()
    }
    
    func windowDidBecomeKey(_ notification: Notification) {
        setFocusToTextField()
    }
    
    func windowWillClose(_ notification: Notification) {
        focusWorkItem?.cancel()
    }
}

// MARK: - 像素风格输入框背景
class PixelInputView: NSView {
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        let bounds = self.bounds
        
        // RPG游戏风格配色 - 深色背景配亮色边框
        let bgColor = CGColor(red: 0.15, green: 0.15, blue: 0.2, alpha: 0.98)  // 深蓝灰背景
        let borderColor = CGColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)  // 亮灰边框
        let innerBorderColor = CGColor(red: 0.5, green: 0.5, blue: 0.6, alpha: 1.0)  // 内边框
        
        // 绘制背景
        context.setFillColor(bgColor)
        drawPixelRect(context, rect: bounds, cornerSize: 3)
        
        // 绘制外边框（2px）
        context.setStrokeColor(borderColor)
        context.setLineWidth(2)
        drawPixelBorder(context, rect: bounds.insetBy(dx: 1, dy: 1), cornerSize: 3)
        
        // 绘制内边框（1px，营造立体感）
        context.setStrokeColor(innerBorderColor)
        context.setLineWidth(1)
        drawPixelBorder(context, rect: bounds.insetBy(dx: 4, dy: 4), cornerSize: 2)
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
        path.addLine(to: CGPoint(x: rect.minX + cs, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + cs))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - cs))
        path.addLine(to: CGPoint(x: rect.minX + cs, y: rect.maxY))
        
        context.addPath(path)
        context.strokePath()
    }
}

// MARK: - 像素风格文本框
class PixelTextField: NSTextField {
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        isBordered = false
        drawsBackground = false
    }
    
    override var acceptsFirstResponder: Bool {
        return true
    }
    
    override func becomeFirstResponder() -> Bool {
        let success = super.becomeFirstResponder()
        if success, let editor = self.currentEditor() as? NSTextView {
            editor.selectAll(nil)
        }
        return success
    }
    
    // 绘制闪烁的光标
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        // 如果不在编辑状态，绘制一个模拟光标
        if window?.firstResponder !== self {
            let context = NSGraphicsContext.current?.cgContext
            context?.setFillColor(NSColor.white.withAlphaComponent(0.5).cgColor)
            context?.fill(CGRect(x: 2, y: 4, width: 2, height: bounds.height - 8))
        }
    }
}

// MARK: - 像素风格按钮
class PixelButton: NSButton {
    
    private var isPressed = false
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        isBordered = false
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }
    
    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        let bounds = self.bounds
        
        // 按钮颜色
        let bgColor = isPressed 
            ? CGColor(red: 0.3, green: 0.5, blue: 0.3, alpha: 1.0)  // 按下时的深绿色
            : CGColor(red: 0.4, green: 0.7, blue: 0.4, alpha: 1.0)  // 正常状态的绿色
        let borderColor = CGColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
        
        // 绘制按钮背景
        context.setFillColor(bgColor)
        let rect = bounds.insetBy(dx: 2, dy: 2)
        context.fill(rect)
        
        // 绘制边框
        context.setStrokeColor(borderColor)
        context.setLineWidth(2)
        context.stroke(rect.insetBy(dx: 1, dy: 1))
        
        // 绘制文字
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font ?? NSFont.monospacedSystemFont(ofSize: 16, weight: .bold),
            .foregroundColor: NSColor.white
        ]
        let attributedTitle = NSAttributedString(string: title, attributes: attributes)
        let size = attributedTitle.size()
        let x = (bounds.width - size.width) / 2
        let y = (bounds.height - size.height) / 2
        attributedTitle.draw(at: CGPoint(x: x, y: y))
    }
    
    override func mouseDown(with event: NSEvent) {
        isPressed = true
        needsDisplay = true
        super.mouseDown(with: event)
    }
    
    override func mouseUp(with event: NSEvent) {
        isPressed = false
        needsDisplay = true
        super.mouseUp(with: event)
    }
}
