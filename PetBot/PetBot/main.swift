// main.swift
// 应用入口点

import Cocoa

// 强制使用中文 - 在应用启动最早期设置
UserDefaults.standard.set(["zh-Hans"], forKey: "AppleLanguages")
UserDefaults.standard.synchronize()
print("[Debug] 设置语言为中文: zh-Hans")

// 创建应用和 delegate
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate

// 运行应用
app.run()
