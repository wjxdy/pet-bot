import Cocoa
import Carbon

class HotKeyManager {
    static let shared = HotKeyManager()
    
    private var eventHandler: EventHandlerRef?
    private var hotKeyRef: EventHotKeyRef?
    
    var onHotKeyPressed: (() -> Void)?
    
    private init() {}
    
    func registerHotKey() {
        // 注册 ⌘+Option+Space 快捷键
        let modifierFlags: UInt32 = UInt32(cmdKey | optionKey)
        let keyCode = UInt32(kVK_Space)
        
        var gMyHotKeyID = EventHotKeyID(signature: FourCharCode(0x504254), id: 1)
        
        let eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: OSType(kEventHotKeyPressed)
        )
        
        // 安装事件处理器
        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, _ -> OSStatus in
                HotKeyManager.shared.handleHotKeyEvent(event)
                return noErr
            },
            1,
            [eventType],
            nil,
            &eventHandler
        )
        
        // 注册热键
        RegisterEventHotKey(
            keyCode,
            modifierFlags,
            gMyHotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        
        print("快捷键 ⌘+Option+Space 已注册")
    }
    
    private func handleHotKeyEvent(_ event: EventRef?) {
        onHotKeyPressed?()
    }
    
    func unregisterHotKey() {
        if let hotKey = hotKeyRef {
            UnregisterEventHotKey(hotKey)
        }
        if let handler = eventHandler {
            RemoveEventHandler(handler)
        }
    }
}
