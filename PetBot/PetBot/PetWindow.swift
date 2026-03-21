// PetWindow.swift
// 宠物悬浮窗口

import SwiftUI

class PetWindow: NSWindow {
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
        
        // 透明无边框窗口
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        
        // 置顶显示
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        
        // 让整个窗口可拖动
        self.isMovableByWindowBackground = true
        
        // 接受鼠标事件
        self.ignoresMouseEvents = false
        
        // 保存到单例
        PetWindowController.shared.petWindow = self
        
        // 初始位置：右下角
        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let windowSize = contentRect.size
            self.setFrameOrigin(CGPoint(
                x: screenRect.maxX - windowSize.width - 20,
                y: 20
            ))
        }
    }
}
