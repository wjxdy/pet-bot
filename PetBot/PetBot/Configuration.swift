// Configuration.swift
// 应用配置管理

import Foundation
import AppKit

enum AppConfiguration {
    // MARK: - OpenClaw Gateway
    static let gatewayHost = "127.0.0.1"
    static let gatewayPort = 18789
    static var gatewayURL: String {
        "http://\(gatewayHost):\(gatewayPort)"
    }
    
    // MARK: - UI Configuration
    static let inputWindowSize = CGSize(width: 400, height: 60)
    static let bubbleMaxWidth: CGFloat = 240
    
    // 动态计算宠物窗口大小（图片按比例缩放，最大高度130px）
    static var petWindowSize: CGSize {
        getScaledImageSize()
    }
    
    private static let maxPetHeight: CGFloat = 130
    
    private static func getScaledImageSize() -> CGSize {
        let targetHeight = petMaxHeight
        
        if let image = NSImage(contentsOfFile: petImagePath) {
            let originalSize = image.size
            
            // 始终缩放到目标高度（小图放大，大图缩小）
            let scale = targetHeight / originalSize.height
            let scaledWidth = originalSize.width * scale
            let scaledHeight = targetHeight
            
            return CGSize(width: scaledWidth, height: scaledHeight + 25)
        }
        return CGSize(width: 100, height: targetHeight + 25)
    }
    
    // MARK: - Assets
    static var petImagePath: String {
        get { UserDefaults.standard.string(forKey: "petImagePath") ?? "/Users/xulei/Desktop/new_a.png" }
        set { UserDefaults.standard.set(newValue, forKey: "petImagePath") }
    }
    
    /// Pet 最大高度（等比例缩放，保持原比例）
    static var petMaxHeight: CGFloat {
        get { 
            let val = UserDefaults.standard.double(forKey: "petMaxHeight")
            return val > 0 ? CGFloat(val) : 130
        }
        set { UserDefaults.standard.set(Double(newValue), forKey: "petMaxHeight") }
    }
    
    // MARK: - Hotkey
    static let hotkeyKeyCode: UInt16 = 0x31 // Space key
    
    // MARK: - User Configurable Settings
    
    /// 气泡自动消失时间（秒），-1 表示永不消失
    static var bubbleAutoHideSeconds: Double {
        get { UserDefaults.standard.double(forKey: "bubbleAutoHideSeconds") }
        set { UserDefaults.standard.set(newValue, forKey: "bubbleAutoHideSeconds") }
    }
    
    /// Pet 初始位置 X
    static var petInitialX: Double {
        get { UserDefaults.standard.double(forKey: "petInitialX") }
        set { UserDefaults.standard.set(newValue, forKey: "petInitialX") }
    }
    
    /// Pet 初始位置 Y
    static var petInitialY: Double {
        get { UserDefaults.standard.double(forKey: "petInitialY") }
        set { UserDefaults.standard.set(newValue, forKey: "petInitialY") }
    }
    
    /// 气泡相对 Pet X 偏移
    static var bubbleOffsetX: Double {
        get { UserDefaults.standard.double(forKey: "bubbleOffsetX") }
        set { UserDefaults.standard.set(newValue, forKey: "bubbleOffsetX") }
    }
    
    /// 气泡相对 Pet Y 偏移
    static var bubbleOffsetY: Double {
        get { UserDefaults.standard.double(forKey: "bubbleOffsetY") }
        set { UserDefaults.standard.set(newValue, forKey: "bubbleOffsetY") }
    }
    
    /// 选中的 Agent ID
    static var selectedAgentId: String {
        get { UserDefaults.standard.string(forKey: "selectedAgentId") ?? "search" }
        set { UserDefaults.standard.set(newValue, forKey: "selectedAgentId") }
    }
    
    /// 是否自动读取 OpenClaw Agent 名字
    static var autoReadAgentName: Bool {
        get { UserDefaults.standard.bool(forKey: "autoReadAgentName") }
        set { UserDefaults.standard.set(newValue, forKey: "autoReadAgentName") }
    }
    
    /// OpenClaw 配置文件夹路径
    static var openclawPath: String {
        get { UserDefaults.standard.string(forKey: "openclawPath") ?? "~/.openclaw" }
        set { UserDefaults.standard.set(newValue, forKey: "openclawPath") }
    }
    
    /// 输入框初始位置 X
    static var inputInitialX: Double {
        get { 
            let val = UserDefaults.standard.double(forKey: "inputInitialX")
            return val != 0 ? val : -1  // -1 表示居中
        }
        set { UserDefaults.standard.set(newValue, forKey: "inputInitialX") }
    }
    
    /// 输入框初始位置 Y
    static var inputInitialY: Double {
        get { 
            let val = UserDefaults.standard.double(forKey: "inputInitialY")
            return val != 0 ? val : -1  // -1 表示居中
        }
        set { UserDefaults.standard.set(newValue, forKey: "inputInitialY") }
    }
    
    /// 聊天记录保存时长（小时），-1 表示永久保存，默认24小时
    static var chatHistoryRetentionHours: Int {
        get {
            // 检查是否有值，如果没有则返回默认值24
            if UserDefaults.standard.object(forKey: "chatHistoryRetentionHours") == nil {
                return 24
            }
            return UserDefaults.standard.integer(forKey: "chatHistoryRetentionHours")
        }
        set { UserDefaults.standard.set(newValue, forKey: "chatHistoryRetentionHours") }
    }
    
    static func registerDefaults() {
        let defaults: [String: Any] = [
            "bubbleAutoHideSeconds": 10.0,
            "petInitialX": 1000.0,
            "petInitialY": 100.0,
            "bubbleOffsetX": 0.0,
            "bubbleOffsetY": 5.0,
            "selectedAgentId": "search",
            "autoReadAgentName": true,
            "petImagePath": "/Users/xulei/Desktop/new_a.png",
            "petMaxHeight": 160.0,
            "inputInitialX": -1.0,
            "inputInitialY": -1.0,
            "chatHistoryRetentionHours": 24
        ]
        UserDefaults.standard.register(defaults: defaults)
    }
}

// MARK: - Logger
enum AppLogger {
    static func info(_ message: String) {
        print("[PetBot ℹ️] \(message)")
    }
    
    static func error(_ message: String) {
        print("[PetBot ❌] \(message)")
    }
    
    static func success(_ message: String) {
        print("[PetBot ✅] \(message)")
    }
}
