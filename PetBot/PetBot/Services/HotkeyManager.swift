// HotkeyManager.swift
// 全局快捷键管理

import Cocoa

class HotkeyManager: NSObject {
    static let shared = HotkeyManager()
    
    var onHotkeyPressed: (() -> Void)?
    
    func register() {
        // 注册全局快捷键 Option + Space
        // 使用 keyCode 49 (Space) + Option 修饰符
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            // 检查是否是 Option + Space
            // keyCode 49 = Space, 58/61 = Option (左右)
            if event.keyCode == 49 && event.modifierFlags.intersection(.deviceIndependentFlagsMask).contains(.option) {
                DispatchQueue.main.async {
                    AppLogger.info("快捷键触发: Option+Space")
                    self?.onHotkeyPressed?()
                }
            }
        }
        
        // 也监听本地事件（当应用处于激活状态时）
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 49 && event.modifierFlags.intersection(.deviceIndependentFlagsMask).contains(.option) {
                DispatchQueue.main.async {
                    AppLogger.info("快捷键触发 (本地): Option+Space")
                    self?.onHotkeyPressed?()
                }
                return nil // 消费掉事件
            }
            return event
        }
        
        AppLogger.success("热键 Option+Space 已注册")
    }
}
