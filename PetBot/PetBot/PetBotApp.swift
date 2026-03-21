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
    let viewModel = AgentViewModel.shared
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        AppLogger.info("PetBot 启动中...")
        
        // 注册默认配置
        AppConfiguration.registerDefaults()
        
        // 设置应用为常规模式（显示在Dock中）
        NSApp.setActivationPolicy(.regular)
        
        setupMainMenu()
        setupPetWindow()
        setupStatusBar()
        setupHotkey()
        
        AppLogger.success("PetBot 启动完成")
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        AppLogger.info("PetBot 正在关闭...")
        InputWindowController.shared.close()
    }
    
    // MARK: - Main Menu
    private func setupMainMenu() {
        let mainMenu = NSMenu()
        
        // PetBot 菜单
        let appMenuItem = NSMenuItem()
        appMenuItem.submenu = createAppMenu()
        mainMenu.addItem(appMenuItem)
        
        // 编辑菜单（支持复制粘贴）
        let editMenuItem = NSMenuItem()
        editMenuItem.submenu = createEditMenu()
        mainMenu.addItem(editMenuItem)
        
        // 窗口菜单
        let windowMenuItem = NSMenuItem()
        windowMenuItem.submenu = createWindowMenu()
        mainMenu.addItem(windowMenuItem)
        
        NSApp.mainMenu = mainMenu
    }
    
    private func createAppMenu() -> NSMenu {
        let menu = NSMenu(title: "PetBot")
        
        // 关于
        menu.addItem(NSMenuItem(title: "关于 PetBot", action: #selector(showAbout), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        
        // 设置
        let settingsItem = NSMenuItem(title: "设置...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.keyEquivalentModifierMask = .command
        menu.addItem(settingsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 隐藏
        menu.addItem(NSMenuItem(title: "隐藏 PetBot", action: #selector(NSApp.hide(_:)), keyEquivalent: "h"))
        menu.addItem(NSMenuItem(title: "隐藏其他", action: #selector(NSApp.hideOtherApplications(_:)), keyEquivalent: "h"))
        menu.addItem(NSMenuItem(title: "显示全部", action: #selector(NSApp.unhideAllApplications(_:)), keyEquivalent: ""))
        
        menu.addItem(NSMenuItem.separator())
        
        // 退出
        let quitItem = NSMenuItem(title: "退出 PetBot", action: #selector(quit), keyEquivalent: "q")
        quitItem.keyEquivalentModifierMask = .command
        menu.addItem(quitItem)
        
        return menu
    }
    
    private func createEditMenu() -> NSMenu {
        let menu = NSMenu(title: "编辑")
        menu.addItem(NSMenuItem(title: "撤销", action: Selector(("undo:")), keyEquivalent: "z"))
        menu.addItem(NSMenuItem(title: "重做", action: Selector(("redo:")), keyEquivalent: "Z"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "剪切", action: #selector(NSText.cut(_:)), keyEquivalent: "x"))
        menu.addItem(NSMenuItem(title: "复制", action: #selector(NSText.copy(_:)), keyEquivalent: "c"))
        menu.addItem(NSMenuItem(title: "粘贴", action: #selector(NSText.paste(_:)), keyEquivalent: "v"))
        menu.addItem(NSMenuItem(title: "全选", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a"))
        return menu
    }
    
    private func createWindowMenu() -> NSMenu {
        let menu = NSMenu(title: "窗口")
        menu.addItem(NSMenuItem(title: "最小化", action: #selector(NSWindow.miniaturize(_:)), keyEquivalent: "m"))
        menu.addItem(NSMenuItem(title: "关闭", action: #selector(NSWindow.close), keyEquivalent: "w"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "前置全部窗口", action: #selector(NSApp.arrangeInFront(_:)), keyEquivalent: ""))
        return menu
    }
    
    @objc private func showAbout() {
        let alert = NSAlert()
        alert.messageText = "PetBot"
        alert.informativeText = "版本 1.0.0\n\n你的桌面 AI 宠物助手\n支持多 Agent 切换"
        alert.alertStyle = .informational
        alert.runModal()
    }
    
    // MARK: - Pet Window
    private func setupPetWindow() {
        petWindow = PetWindow(
            contentRect: NSRect(origin: .zero, size: AppConfiguration.petWindowSize),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        let contentView = PetView(petWindow: petWindow)
        petWindow?.contentView = NSHostingView(rootView: contentView)
        petWindow?.makeKeyAndOrderFront(nil)
    }
    
    // MARK: - Status Bar
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
        menu.addItem(NSMenuItem(title: "打开设置", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "退出", action: #selector(quit), keyEquivalent: "q"))
        
        statusItem?.menu = menu
    }
    
    // MARK: - Hotkey
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
    
    // MARK: - Settings
    @objc private func openSettings() {
        let controller = SettingsWindowController()
        controller.setup(with: viewModel)
        controller.showSettings()
    }
    
    // MARK: - Quit
    @objc private func quit() {
        InputWindowController.shared.close()
        NSApp.terminate(nil)
    }
}
