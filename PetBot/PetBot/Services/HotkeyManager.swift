// HotkeyManager.swift
// 全局快捷键管理 - 使用 Carbon API 实现可靠的全局监听

import Carbon
import Cocoa

class HotkeyManager {
    static let shared = HotkeyManager()
    
    var onHotkeyPressed: (() -> Void)?
    private var eventHandler: EventHandlerRef?
    private var hotKeyRef: EventHotKeyRef?
    private let hotKeyID = EventHotKeyID(signature: FourCharCode("PBOT") ?? 0, id: 1)
    
    func register() {
        // 安装事件处理器
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        
        let callback: EventHandlerUPP = { _, event, _ -> OSStatus in
            // 获取热键 ID
            var hotKeyID = EventHotKeyID()
            GetEventParameter(
                event,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hotKeyID
            )
            
            if hotKeyID.id == 1 {
                DispatchQueue.main.async {
                    AppLogger.info("全局快捷键触发")
                    HotkeyManager.shared.onHotkeyPressed?()
                }
            }
            return noErr
        }
        
        InstallEventHandler(
            GetApplicationEventTarget(),
            callback,
            1,
            &eventType,
            nil,
            &eventHandler
        )
        
        // 注册 Option + Space 热键
        // keyCode: 49 = Space
        // modifiers: optionKey
        let status = RegisterEventHotKey(
            UInt32(49), // Space
            UInt32(optionKey),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        
        if status == noErr {
            AppLogger.success("全局快捷键 Option+Space 已注册")
        } else {
            AppLogger.error("注册快捷键失败: \(status)")
        }
    }
    
    func unregister() {
        if let hotKey = hotKeyRef {
            UnregisterEventHotKey(hotKey)
        }
        if let handler = eventHandler {
            RemoveEventHandler(handler)
        }
    }
}
