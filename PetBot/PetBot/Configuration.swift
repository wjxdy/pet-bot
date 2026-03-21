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
    static let petWindowSize = CGSize(width: 360, height: 400)
    static let inputWindowSize = CGSize(width: 300, height: 100)
    static let bubbleMaxWidth: CGFloat = 260
    
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
