// HotkeyManager.swift
// 全局快捷键管理

import Carbon
import Cocoa

class HotkeyManager {
    static let shared = HotkeyManager()
    
    var onHotkeyPressed: (() -> Void)?
    
    private var eventHandler: EventHandlerRef?
    private let hotKeyID = EventHotKeyID(signature: FourCharCode("DPET") ?? 0, id: 1)
    private var registeredHotKey: EventHotKeyRef?
    
    private init() {}
    
    func registerHotkey() {
        // 注册 Option + Space
        let modifierFlags: UInt32 = UInt32(optionKey)
        let keyCode: UInt32 = UInt32(kVK_Space)
        
        // 注册热键
        let status = RegisterEventHotKey(
            keyCode,
            modifierFlags,
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            &registeredHotKey
        )
        
        guard status == noErr else {
            print("热键注册失败: \(status)")
            return
        }
        
        // 设置事件回调
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        
        let callback: EventHandlerUPP = { _, event, _ -> OSStatus in
            HotkeyManager.shared.onHotkeyPressed?()
            return noErr
        }
        
        InstallEventHandler(
            GetEventDispatcherTarget(),
            callback,
            1,
            &eventType,
            nil,
            &eventHandler
        )
        
        print("热键 Option+Space 已注册")
    }
    
    func unregisterHotkey() {
        if let hotKey = registeredHotKey {
            UnregisterEventHotKey(hotKey)
            registeredHotKey = nil
        }
        
        if let handler = eventHandler {
            RemoveEventHandler(handler)
            eventHandler = nil
        }
    }
    
    deinit {
        unregisterHotkey()
    }
}

// 快捷键代码参考
extension HotkeyManager {
    // 常用按键代码
    static let keyCodes: [String: UInt32] = [
        "A": UInt32(kVK_ANSI_A),
        "B": UInt32(kVK_ANSI_B),
        "C": UInt32(kVK_ANSI_C),
        "D": UInt32(kVK_ANSI_D),
        "E": UInt32(kVK_ANSI_E),
        "F": UInt32(kVK_ANSI_F),
        "G": UInt32(kVK_ANSI_G),
        "H": UInt32(kVK_ANSI_H),
        "I": UInt32(kVK_ANSI_I),
        "J": UInt32(kVK_ANSI_J),
        "K": UInt32(kVK_ANSI_K),
        "L": UInt32(kVK_ANSI_L),
        "M": UInt32(kVK_ANSI_M),
        "N": UInt32(kVK_ANSI_N),
        "O": UInt32(kVK_ANSI_O),
        "P": UInt32(kVK_ANSI_P),
        "Q": UInt32(kVK_ANSI_Q),
        "R": UInt32(kVK_ANSI_R),
        "S": UInt32(kVK_ANSI_S),
        "T": UInt32(kVK_ANSI_T),
        "U": UInt32(kVK_ANSI_U),
        "V": UInt32(kVK_ANSI_V),
        "W": UInt32(kVK_ANSI_W),
        "X": UInt32(kVK_ANSI_X),
        "Y": UInt32(kVK_ANSI_Y),
        "Z": UInt32(kVK_ANSI_Z),
        "Space": UInt32(kVK_Space),
        "Return": UInt32(kVK_Return),
        "Escape": UInt32(kVK_Escape),
        "Tab": UInt32(kVK_Tab)
    ]
}
