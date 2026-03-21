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
        // 直接在这里创建设置窗口，避免模块问题
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 500),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "PetBot 设置"
        window.center()
        
        // 创建内容视图
        let contentView = NSView(frame: NSRect(x: 0, y: 0, width: 480, height: 500))
        
        var y: CGFloat = 450
        
        // 标题
        let title = NSTextField(labelWithString: "PetBot 设置")
        title.font = NSFont.systemFont(ofSize: 20, weight: .semibold)
        title.sizeToFit()
        title.frame.origin = CGPoint(x: 20, y: y)
        contentView.addSubview(title)
        
        y -= 60
        
        // 气泡设置
        let bubbleLabel = NSTextField(labelWithString: "气泡设置")
        bubbleLabel.font = NSFont.systemFont(ofSize: 16, weight: .medium)
        bubbleLabel.textColor = .secondaryLabelColor
        bubbleLabel.sizeToFit()
        bubbleLabel.frame.origin = CGPoint(x: 20, y: y)
        contentView.addSubview(bubbleLabel)
        
        y -= 40
        
        // 自动消失时间
        let timeLabel = NSTextField(labelWithString: "自动消失时间:")
        timeLabel.sizeToFit()
        timeLabel.frame.origin = CGPoint(x: 40, y: y)
        contentView.addSubview(timeLabel)
        
        let timePopUp = NSPopUpButton(frame: NSRect(x: 160, y: y, width: 150, height: 25))
        timePopUp.addItems(withTitles: ["5秒", "10秒", "15秒", "30秒", "永不"])
        let currentTime = UserDefaults.standard.double(forKey: "bubbleAutoHideSeconds")
        let times: [Double] = [5, 10, 15, 30, -1]
        if let index = times.firstIndex(of: currentTime) {
            timePopUp.selectItem(at: index)
        } else {
            timePopUp.selectItem(at: 1)
        }
        contentView.addSubview(timePopUp)
        
        y -= 50
        
        // Pet 初始位置
        let petLabel = NSTextField(labelWithString: "Pet 初始位置")
        petLabel.font = NSFont.systemFont(ofSize: 16, weight: .medium)
        petLabel.textColor = .secondaryLabelColor
        petLabel.sizeToFit()
        petLabel.frame.origin = CGPoint(x: 20, y: y)
        contentView.addSubview(petLabel)
        
        y -= 40
        
        // X 位置
        let petXLabel = NSTextField(labelWithString: "X:")
        petXLabel.sizeToFit()
        petXLabel.frame.origin = CGPoint(x: 40, y: y)
        contentView.addSubview(petXLabel)
        
        let petXField = NSTextField(frame: NSRect(x: 70, y: y, width: 80, height: 22))
        petXField.stringValue = "\(Int(UserDefaults.standard.double(forKey: "petInitialX")))"
        contentView.addSubview(petXField)
        
        // Y 位置
        let petYLabel = NSTextField(labelWithString: "Y:")
        petYLabel.sizeToFit()
        petYLabel.frame.origin = CGPoint(x: 170, y: y)
        contentView.addSubview(petYLabel)
        
        let petYField = NSTextField(frame: NSRect(x: 200, y: y, width: 80, height: 22))
        petYField.stringValue = "\(Int(UserDefaults.standard.double(forKey: "petInitialY")))"
        contentView.addSubview(petYField)
        
        y -= 50
        
        // AI 模型配置
        let aiLabel = NSTextField(labelWithString: "AI 模型配置")
        aiLabel.font = NSFont.systemFont(ofSize: 16, weight: .medium)
        aiLabel.textColor = .secondaryLabelColor
        aiLabel.sizeToFit()
        aiLabel.frame.origin = CGPoint(x: 20, y: y)
        contentView.addSubview(aiLabel)
        
        y -= 40
        
        // 提供商选择
        let providerLabel = NSTextField(labelWithString: "提供商:")
        providerLabel.sizeToFit()
        providerLabel.frame.origin = CGPoint(x: 40, y: y)
        contentView.addSubview(providerLabel)
        
        let providerPopUp = NSPopUpButton(frame: NSRect(x: 120, y: y, width: 200, height: 25))
        providerPopUp.addItems(withTitles: ["OpenAI", "Anthropic Claude", "OpenClaw Gateway"])
        contentView.addSubview(providerPopUp)
        
        y -= 40
        
        // OpenClaw 路径设置
        let pathLabel = NSTextField(labelWithString: "OpenClaw 路径:")
        pathLabel.sizeToFit()
        pathLabel.frame.origin = CGPoint(x: 40, y: y)
        contentView.addSubview(pathLabel)
        
        let pathField = NSTextField(frame: NSRect(x: 160, y: y, width: 250, height: 22))
        pathField.stringValue = AppConfiguration.openclawPath
        contentView.addSubview(pathField)
        
        y -= 50
        
        // Agent 选择
        let agentLabel = NSTextField(labelWithString: "Agent 选择")
        agentLabel.font = NSFont.systemFont(ofSize: 16, weight: .medium)
        agentLabel.textColor = .secondaryLabelColor
        agentLabel.sizeToFit()
        agentLabel.frame.origin = CGPoint(x: 20, y: y)
        contentView.addSubview(agentLabel)
        
        y -= 40
        
        // Agent 单选按钮
        for (index, agent) in viewModel.availableAgents.enumerated() {
            let button = NSButton(frame: NSRect(x: 40, y: y, width: 400, height: 24))
            button.title = "\(agent.icon) \(agent.name)"
            button.setButtonType(.radio)
            button.state = agent.id == viewModel.currentAgent.id ? .on : .off
            button.tag = index
            button.target = self
            button.action = #selector(settingsAgentSelected(_:))
            contentView.addSubview(button)
            y -= 30
        }
        
        // 完成按钮
        let doneButton = NSButton(frame: NSRect(x: 380, y: 20, width: 80, height: 28))
        doneButton.title = "完成"
        doneButton.bezelStyle = .rounded
        doneButton.keyEquivalent = "\r"
        doneButton.target = self
        doneButton.action = #selector(closeSettingsWindow(_:))
        contentView.addSubview(doneButton)
        
        window.contentView = contentView
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc private func settingsAgentSelected(_ sender: NSButton) {
        let agents = viewModel.availableAgents
        guard sender.tag >= 0 && sender.tag < agents.count else { return }
        viewModel.switchAgent(agents[sender.tag])
    }
    
    @objc private func closeSettingsWindow(_ sender: NSButton) {
        guard let window = sender.window, let contentView = window.contentView else { return }
        
        // 查找并保存设置
        for view in contentView.subviews {
            if let textField = view as? NSTextField {
                // 通过位置识别 X 和 Y 字段
                if textField.frame.origin.x == 70 && textField.frame.width == 80 {
                    if let x = Double(textField.stringValue) {
                        UserDefaults.standard.set(x, forKey: "petInitialX")
                    }
                } else if textField.frame.origin.x == 200 && textField.frame.width == 80 {
                    if let y = Double(textField.stringValue) {
                        UserDefaults.standard.set(y, forKey: "petInitialY")
                    }
                } else if textField.frame.origin.x == 160 && textField.frame.width == 250 {
                    // OpenClaw 路径
                    AppConfiguration.openclawPath = textField.stringValue
                }
            }
        }
        
        // 关闭窗口
        window.close()
    }
    
    // MARK: - Quit
    @objc private func quit() {
        InputWindowController.shared.close()
        NSApp.terminate(nil)
    }
}
