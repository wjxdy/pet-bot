// PetWindow.swift
// 宠物悬浮窗口

import SwiftUI

class PetWindow: NSWindow {
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
        
        configureWindow()
        setupInitialPosition()
    }
    
    private func configureWindow() {
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        isMovableByWindowBackground = true
        ignoresMouseEvents = false
    }
    
    private func setupInitialPosition() {
        let x = AppConfiguration.petInitialX
        let y = AppConfiguration.petInitialY
        
        setFrameOrigin(NSPoint(x: x, y: y))
    }
}
