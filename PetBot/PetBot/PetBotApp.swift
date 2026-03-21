// PetBotApp.swift
// 应用入口

import SwiftUI
import AppKit

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
    let viewModel = AgentViewModel()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        AppLogger.info("PetBot 启动中...")
        
        setupPetWindow()
        setupStatusBar()
        setupHotkey()
        
        NSApp.setActivationPolicy(.accessory)
        AppLogger.success("PetBot 启动完成")
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        AppLogger.info("PetBot 正在关闭...")
        InputWindowController.shared.close()
    }
    
    private func setupPetWindow() {
        // 先创建窗口
        petWindow = PetWindow(
            contentRect: NSRect(origin: .zero, size: AppConfiguration.petWindowSize),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        // 再创建视图，传入窗口引用
        let contentView = PetView(petWindow: petWindow)
        
        petWindow?.contentView = NSHostingView(rootView: contentView)
        petWindow?.makeKeyAndOrderFront(nil)
        
        // 窗口移动时更新气泡位置
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidMove),
            name: NSWindow.didMoveNotification,
            object: petWindow
        )
    }
    
    @objc private func windowDidMove() {
        // 宠物窗口移动时，气泡窗口会跟随（因为它们是独立的）
        // 如果气泡可见，更新其位置
        if BubbleWindowController.shared.isVisible {
            BubbleWindowController.shared.show(
                text: "",
                anchorWindow: petWindow
            )
        }
    }
    
    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "bubble.left.fill", accessibilityDescription: "PetBot")
        }
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "显示/隐藏输入框", action: #selector(toggleInput), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        
        // Agent 切换菜单
        let agentMenu = NSMenu(title: "切换 Agent")
        for agent in viewModel.availableAgents {
            let item = NSMenuItem(title: agent.name, action: #selector(switchAgent(_:)), keyEquivalent: "")
            item.representedObject = agent.id
            item.state = agent.id == viewModel.currentAgent.id ? .on : .off
            agentMenu.addItem(item)
        }
        
        let agentItem = NSMenuItem(title: "切换 Agent", action: nil, keyEquivalent: "")
        agentItem.submenu = agentMenu
        menu.addItem(agentItem)
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "退出", action: #selector(quit), keyEquivalent: "q"))
        
        statusItem?.menu = menu
    }
    
    private func setupHotkey() {
        HotkeyManager.shared.register()
        HotkeyManager.shared.onHotkeyPressed = { [weak self] in
            self?.toggleInput()
        }
    }
    
    @objc private func toggleInput() {
        NotificationCenter.default.post(name: Notification.Name("toggleInput"), object: nil)
    }
    
    @objc private func switchAgent(_ sender: NSMenuItem) {
        guard let agentId = sender.representedObject as? String,
              let agent = viewModel.availableAgents.first(where: { $0.id == agentId }) else { return }
        
        viewModel.switchAgent(agent)
        
        if let menu = statusItem?.menu?.item(withTitle: "切换 Agent")?.submenu {
            for item in menu.items {
                item.state = (item.representedObject as? String) == agentId ? .on : .off
            }
        }
    }
    
    @objc private func quit() {
        InputWindowController.shared.close()
        NSApp.terminate(nil)
    }
}
