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
    
    // 动态计算宠物窗口大小（根据图片尺寸）
    static var petWindowSize: CGSize {
        getImageSize()
    }
    
    // 获取图片尺寸并添加边距
    private static func getImageSize() -> CGSize {
        if let image = NSImage(contentsOfFile: petImagePath) {
            let size = image.size
            // 图片尺寸 + 底部空间给名字标签
            return CGSize(width: size.width, height: size.height + 30)
        }
        // 默认尺寸
        return CGSize(width: 200, height: 290)
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
