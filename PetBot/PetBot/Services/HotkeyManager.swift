// HotkeyManager.swift
// 全局快捷键管理 - 简化版

import Carbon
import Cocoa

class HotkeyManager: NSObject {
    static let shared = HotkeyManager()
    
    var onHotkeyPressed: (() -> Void)?
    
    private var hotKeyRef: EventHotKeyRef?
    
    func register() {
        // 使用简单的 NSEvent 监控
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            // Option + Space
            if event.keyCode == 49 && event.modifierFlags.contains(.option) {
                DispatchQueue.main.async {
                    self?.onHotkeyPressed?()
                }
            }
        }
        
        AppLogger.success("热键 Option+Space 已注册")
    }
}
