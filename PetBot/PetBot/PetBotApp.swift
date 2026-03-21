// PetBotApp.swift
// 应用入口

import SwiftUI

@main
struct PetBotApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    var petWindow: PetWindow?
    var statusItem: NSStatusItem?
    var agentManager = AgentManager()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 创建宠物窗口
        createPetWindow()
        
        // 创建状态栏图标
        createStatusBarItem()
        
        // 注册全局快捷键
        HotkeyManager.shared.registerHotkey()
        HotkeyManager.shared.onHotkeyPressed = { [weak self] in
            self?.toggleInput()
        }
        
        // 隐藏 Dock 图标
        NSApp.setActivationPolicy(.accessory)
        
        // 启动时只显示宠物
        // 按 Option+Space 唤出输入框（独立窗口，位置可记忆）
    }
    
    func createPetWindow() {
        let contentView = PetView(agentManager: agentManager)
            .environmentObject(agentManager)
        
        petWindow = PetWindow(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 440),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        petWindow?.contentView = NSHostingView(rootView: contentView)
        petWindow?.makeKeyAndOrderFront(nil)
    }
    
    func createStatusBarItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "bubble.left.fill", accessibilityDescription: "PetBot")
        }
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "显示/隐藏输入框", action: #selector(toggleInput), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        
        // Agent 切换菜单
        let agentMenu = NSMenu(title: "切换 Agent")
        for agent in agentManager.availableAgents {
            let item = NSMenuItem(
                title: agent.name,
                action: #selector(switchAgent(_:)),
                keyEquivalent: ""
            )
            item.representedObject = agent.id
            item.state = agent.id == agentManager.currentAgent.id ? .on : .off
            agentMenu.addItem(item)
        }
        
        let agentItem = NSMenuItem(title: "切换 Agent", action: nil, keyEquivalent: "")
        agentItem.submenu = agentMenu
        menu.addItem(agentItem)
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "退出", action: #selector(quit), keyEquivalent: "q"))
        
        statusItem?.menu = menu
    }
    
    @objc func toggleInput() {
        // 切换输入框窗口
        NotificationCenter.default.post(name: .toggleChat, object: nil)
    }
    
    @objc func switchAgent(_ sender: NSMenuItem) {
        if let agentId = sender.representedObject as? String {
            agentManager.switchToAgent(agentId)
        }
    }
    
    @objc func quit() {
        // 关闭输入框窗口
        InputWindowController.shared.close()
        NSApp.terminate(nil)
    }
}

extension Notification.Name {
    static let toggleChat = Notification.Name("toggleChat")
}
