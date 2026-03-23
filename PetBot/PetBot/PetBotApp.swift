// PetBotApp.swift
// 应用入口

import SwiftUI
import AppKit

@main
struct PetBotApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        // 强制使用中文 - 在应用启动最早期设置
        UserDefaults.standard.set(["zh-Hans"], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
    }
    
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
        let menu = NSMenu(title: NSLocalizedString("PetBot", comment: "App menu title"))
        
        // 关于
        let aboutItem = NSMenuItem(title: NSLocalizedString("About PetBot", comment: "About menu item"), action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)
        menu.addItem(NSMenuItem.separator())
        
        // 聊天历史
        let chatHistoryItem = NSMenuItem(title: NSLocalizedString("Open Chat History", comment: "Chat history menu item"), action: #selector(openChatHistory), keyEquivalent: "")
        chatHistoryItem.target = self
        menu.addItem(chatHistoryItem)
        menu.addItem(NSMenuItem.separator())
        
        // 设置
        let settingsItem = NSMenuItem(title: NSLocalizedString("Settings...", comment: "Settings menu item"), action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.keyEquivalentModifierMask = .command
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 隐藏
        menu.addItem(NSMenuItem(title: NSLocalizedString("Hide PetBot", comment: "Hide menu item"), action: #selector(NSApp.hide(_:)), keyEquivalent: "h"))
        menu.addItem(NSMenuItem(title: NSLocalizedString("Hide Others", comment: "Hide others menu item"), action: #selector(NSApp.hideOtherApplications(_:)), keyEquivalent: "h"))
        menu.addItem(NSMenuItem(title: NSLocalizedString("Show All", comment: "Show all menu item"), action: #selector(NSApp.unhideAllApplications(_:)), keyEquivalent: ""))
        
        menu.addItem(NSMenuItem.separator())
        
        // 退出
        let quitItem = NSMenuItem(title: NSLocalizedString("Quit PetBot", comment: "Quit menu item"), action: #selector(quit), keyEquivalent: "q")
        quitItem.keyEquivalentModifierMask = .command
        quitItem.target = self
        menu.addItem(quitItem)
        
        return menu
    }
    
    private func createEditMenu() -> NSMenu {
        let menu = NSMenu(title: NSLocalizedString("Edit", comment: "Edit menu title"))
        menu.addItem(NSMenuItem(title: NSLocalizedString("Undo", comment: "Undo menu item"), action: Selector(("undo:")), keyEquivalent: "z"))
        menu.addItem(NSMenuItem(title: NSLocalizedString("Redo", comment: "Redo menu item"), action: Selector(("redo:")), keyEquivalent: "Z"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: NSLocalizedString("Cut", comment: "Cut menu item"), action: #selector(NSText.cut(_:)), keyEquivalent: "x"))
        menu.addItem(NSMenuItem(title: NSLocalizedString("Copy", comment: "Copy menu item"), action: #selector(NSText.copy(_:)), keyEquivalent: "c"))
        menu.addItem(NSMenuItem(title: NSLocalizedString("Paste", comment: "Paste menu item"), action: #selector(NSText.paste(_:)), keyEquivalent: "v"))
        menu.addItem(NSMenuItem(title: NSLocalizedString("Select All", comment: "Select all menu item"), action: #selector(NSText.selectAll(_:)), keyEquivalent: "a"))
        return menu
    }
    
    private func createWindowMenu() -> NSMenu {
        let menu = NSMenu(title: NSLocalizedString("Window", comment: "Window menu title"))
        menu.addItem(NSMenuItem(title: NSLocalizedString("Minimize", comment: "Minimize menu item"), action: #selector(NSWindow.miniaturize(_:)), keyEquivalent: "m"))
        menu.addItem(NSMenuItem(title: NSLocalizedString("Close", comment: "Close menu item"), action: #selector(NSWindow.close), keyEquivalent: "w"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: NSLocalizedString("Bring All to Front", comment: "Bring all to front menu item"), action: #selector(NSApp.arrangeInFront(_:)), keyEquivalent: ""))
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
        // 先创建窗口
        let newWindow = PetWindow(
            contentRect: NSRect(origin: .zero, size: AppConfiguration.petWindowSize),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        self.petWindow = newWindow
        
        // 再创建内容视图，确保 petWindow 已设置
        let contentView = PetView(petWindow: newWindow)
        newWindow.contentView = NSHostingView(rootView: contentView)
        newWindow.makeKeyAndOrderFront(nil)
    }
    
    // MARK: - Status Bar
    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "bubble.left.fill", accessibilityDescription: "PetBot")
        }
        
        let menu = NSMenu()
        
        let toggleItem = NSMenuItem(title: NSLocalizedString("Show/Hide Input", comment: "Toggle input menu item"), action: #selector(toggleInput), keyEquivalent: "")
        toggleItem.target = self
        menu.addItem(toggleItem)
        menu.addItem(NSMenuItem.separator())
        
        // Agent 切换菜单
        let agentMenu = NSMenu(title: NSLocalizedString("Switch Agent", comment: "Switch agent menu title"))
        for agent in viewModel.availableAgents {
            let item = NSMenuItem(title: agent.name, action: #selector(switchAgent(_:)), keyEquivalent: "")
            item.representedObject = agent.id
            item.state = agent.id == viewModel.currentAgent.id ? .on : .off
            item.target = self
            agentMenu.addItem(item)
        }
        
        let agentItem = NSMenuItem(title: NSLocalizedString("Switch Agent", comment: "Switch agent menu item"), action: nil, keyEquivalent: "")
        agentItem.submenu = agentMenu
        menu.addItem(agentItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let historyItem = NSMenuItem(title: NSLocalizedString("Open Chat History", comment: "Chat history menu item"), action: #selector(openChatHistory), keyEquivalent: "h")
        historyItem.target = self
        menu.addItem(historyItem)
        menu.addItem(NSMenuItem.separator())
        
        let settingsItem = NSMenuItem(title: NSLocalizedString("Open Settings", comment: "Open settings menu item"), action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: NSLocalizedString("Quit", comment: "Quit menu item"), action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
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
        
        if let menu = statusItem?.menu?.item(withTitle: NSLocalizedString("Switch Agent", comment: "Switch agent menu title"))?.submenu {
            for item in menu.items {
                item.state = (item.representedObject as? String) == agentId ? .on : .off
            }
        }
    }
    
    // MARK: - Settings
    @objc private func openChatHistory() {
        print("[Debug] openChatHistory called")
        print("[Debug] viewModel.availableAgents.count = \(viewModel.availableAgents.count)")
        
        // 确保在主线程执行
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                print("[Error] self is nil in openChatHistory")
                return
            }
            
            ChatHistoryManager.show(viewModel: self.viewModel)
        }
    }
    
    @objc private func openSettings() {
        print("[Debug] openSettings called")
        print("[Debug] SettingsWindowController.shared = \(String(describing: SettingsWindowController.shared))")
        print("[Debug] viewModel.availableAgents.count = \(viewModel.availableAgents.count)")
        
        // 确保在主线程执行
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                print("[Error] self is nil in openSettings")
                return
            }
            
            // 如果已存在窗口，直接显示
            if let existingController = SettingsWindowController.shared {
                print("[Debug] Showing existing settings window")
                existingController.showWindow(nil)
                return
            }
            
            // 创建新窗口
            print("[Debug] Creating new settings window")
            let controller = SettingsWindowController()
            controller.setup(with: self.viewModel)
            controller.showSettings()
        }
    }
    
    // MARK: - Quit
    @objc private func quit() {
        InputWindowController.shared.close()
        NSApp.terminate(nil)
    }
}
