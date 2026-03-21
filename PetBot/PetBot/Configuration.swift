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
    
    // MARK: - Default Agent
    static let defaultAgentId = "search" // 小米鼠
    
    // MARK: - UI Configuration
    // 窗口大小自动根据图片尺寸计算
    static let inputWindowSize = CGSize(width: 300, height: 100)
    static let bubbleMaxWidth: CGFloat = 200
    
    // 动态计算宠物窗口大小（图片按比例缩放，最大高度160px）
    static var petWindowSize: CGSize {
        getScaledImageSize()
    }
    
    private static let maxPetHeight: CGFloat = 160
    
    private static func getScaledImageSize() -> CGSize {
        if let image = NSImage(contentsOfFile: petImagePath) {
            let originalSize = image.size
            let scale = min(1.0, maxPetHeight / originalSize.height)
            let scaledWidth = originalSize.width * scale
            let scaledHeight = originalSize.height * scale
            // 窗口大小 = 缩放后图片 + 名字标签空间
            return CGSize(width: scaledWidth, height: scaledHeight + 25)
        }
        return CGSize(width: 123, height: 185) // 默认 (200*0.615, 160+25)
    }
    
    // MARK: - Assets
    static let petImagePath = "/Users/xulei/Desktop/new_a.png"
    
    // MARK: - Hotkey
    static let hotkeyKeyCode: UInt16 = 0x31 // Space key
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
