// PetWindow.swift
// 宠物悬浮窗口 - 圆角 + 阴影

import SwiftUI

class PetWindow: NSWindow {
    private let cornerRadius: CGFloat = 16
    
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
        
        configureWindow()
        setupInitialPosition()
        applyVisualEffects()
    }
    
    private func configureWindow() {
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true  // 启用系统阴影
        
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        isMovableByWindowBackground = true
        ignoresMouseEvents = false
        
        // 设置圆角遮罩
        applyRoundedCorners()
    }
    
    private func applyVisualEffects() {
        // 添加背景模糊效果
        let visualEffectView = NSVisualEffectView(frame: contentView?.bounds ?? .zero)
        visualEffectView.material = .popover
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.state = .active
        visualEffectView.wantsLayer = true
        visualEffectView.layer?.cornerRadius = cornerRadius
        visualEffectView.layer?.masksToBounds = true
        visualEffectView.autoresizingMask = [.width, .height]
        
        // 插入到最底层
        if let contentView = contentView {
            contentView.wantsLayer = true
            contentView.layer?.cornerRadius = cornerRadius
            contentView.layer?.masksToBounds = true
            contentView.addSubview(visualEffectView, positioned: .below, relativeTo: nil)
        }
    }
    
    private func applyRoundedCorners() {
        guard let contentView = contentView else { return }
        
        contentView.wantsLayer = true
        contentView.layer?.cornerRadius = cornerRadius
        contentView.layer?.masksToBounds = true
        
        // 设置窗口形状为圆角矩形
        if #available(macOS 10.15, *) {
            contentView.layer?.cornerCurve = .continuous
        }
    }
    
    private func setupInitialPosition() {
        let x = AppConfiguration.petInitialX
        let y = AppConfiguration.petInitialY
        
        setFrameOrigin(NSPoint(x: x, y: y))
    }
    
    // 更新窗口大小后重新应用效果
    override func setFrame(_ frameRect: NSRect, display flag: Bool) {
        super.setFrame(frameRect, display: flag)
        applyRoundedCorners()
    }
}
