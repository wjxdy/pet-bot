// SettingsWindow.swift
// 设置窗口 - 带滚动条

import Cocoa

class SettingsWindowController: NSWindowController {
    static var shared: SettingsWindowController?
    
    private var viewModel: AgentViewModel!
    
    func setup(with viewModel: AgentViewModel) {
        self.viewModel = viewModel
    }
    
    func showSettings() {
        SettingsWindowController.shared = self
        
        // 计算内容高度（根据 agent 数量）
        let agentCount = viewModel.availableAgents.count
        let contentHeight: CGFloat = 520 + CGFloat(agentCount * 35)
        let windowHeight: CGFloat = min(600, contentHeight)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: windowHeight),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "PetBot 设置"
        window.center()
        window.minSize = NSSize(width: 480, height: 400)
        
        // 创建滚动视图
        let scrollView = NSScrollView(frame: NSRect(x: 0, y: 50, width: 480, height: windowHeight - 50))
        scrollView.autoresizingMask = [.width, .height]
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        
        // 创建文档视图（内容容器）
        let documentView = NSView(frame: NSRect(x: 0, y: 0, width: 460, height: contentHeight))
        documentView.autoresizesSubviews = true
        
        var y: CGFloat = contentHeight - 30
        
        // 标题
        let title = NSTextField(labelWithString: "PetBot 设置")
        title.font = NSFont.systemFont(ofSize: 20, weight: .semibold)
        title.sizeToFit()
        title.frame.origin = CGPoint(x: 20, y: y)
        documentView.addSubview(title)
        
        y -= 50
        
        // 气泡设置
        let bubbleLabel = NSTextField(labelWithString: "气泡设置")
        bubbleLabel.font = NSFont.systemFont(ofSize: 16, weight: .medium)
        bubbleLabel.textColor = .secondaryLabelColor
        bubbleLabel.sizeToFit()
        bubbleLabel.frame.origin = CGPoint(x: 20, y: y)
        documentView.addSubview(bubbleLabel)
        
        y -= 35
        
        // 自动消失时间
        let timeLabel = NSTextField(labelWithString: "自动消失时间:")
        timeLabel.sizeToFit()
        timeLabel.frame.origin = CGPoint(x: 40, y: y)
        documentView.addSubview(timeLabel)
        
        let timePopUp = NSPopUpButton(frame: NSRect(x: 160, y: y, width: 150, height: 25))
        timePopUp.tag = 1001
        timePopUp.addItems(withTitles: ["5秒", "10秒", "15秒", "30秒", "永不"])
        let currentTime = UserDefaults.standard.double(forKey: "bubbleAutoHideSeconds")
        let times: [Double] = [5, 10, 15, 30, -1]
        if let index = times.firstIndex(of: currentTime) {
            timePopUp.selectItem(at: index)
        } else {
            timePopUp.selectItem(at: 1)
        }
        documentView.addSubview(timePopUp)
        
        y -= 45
        
        // Pet 初始位置
        let petLabel = NSTextField(labelWithString: "Pet 初始位置")
        petLabel.font = NSFont.systemFont(ofSize: 16, weight: .medium)
        petLabel.textColor = .secondaryLabelColor
        petLabel.sizeToFit()
        petLabel.frame.origin = CGPoint(x: 20, y: y)
        documentView.addSubview(petLabel)
        
        y -= 35
        
        // Pet X 位置
        let petXLabel = NSTextField(labelWithString: "X:")
        petXLabel.sizeToFit()
        petXLabel.frame.origin = CGPoint(x: 40, y: y)
        documentView.addSubview(petXLabel)
        
        let petXField = NSTextField(frame: NSRect(x: 70, y: y, width: 80, height: 22))
        petXField.tag = 1002
        petXField.stringValue = "\(Int(UserDefaults.standard.double(forKey: "petInitialX")))"
        documentView.addSubview(petXField)
        
        // Pet Y 位置
        let petYLabel = NSTextField(labelWithString: "Y:")
        petYLabel.sizeToFit()
        petYLabel.frame.origin = CGPoint(x: 170, y: y)
        documentView.addSubview(petYLabel)
        
        let petYField = NSTextField(frame: NSRect(x: 200, y: y, width: 80, height: 22))
        petYField.tag = 1003
        petYField.stringValue = "\(Int(UserDefaults.standard.double(forKey: "petInitialY")))"
        documentView.addSubview(petYField)
        
        y -= 45
        
        // 气泡框位置设置
        let bubblePosLabel = NSTextField(labelWithString: "气泡框位置偏移")
        bubblePosLabel.font = NSFont.systemFont(ofSize: 16, weight: .medium)
        bubblePosLabel.textColor = .secondaryLabelColor
        bubblePosLabel.sizeToFit()
        bubblePosLabel.frame.origin = CGPoint(x: 20, y: y)
        documentView.addSubview(bubblePosLabel)
        
        y -= 35
        
        // 气泡框 X 偏移
        let bubbleXLabel = NSTextField(labelWithString: "X 偏移:")
        bubbleXLabel.sizeToFit()
        bubbleXLabel.frame.origin = CGPoint(x: 40, y: y)
        documentView.addSubview(bubbleXLabel)
        
        let bubbleXField = NSTextField(frame: NSRect(x: 110, y: y, width: 80, height: 22))
        bubbleXField.tag = 1004
        bubbleXField.stringValue = "\(Int(UserDefaults.standard.double(forKey: "bubbleOffsetX")))"
        documentView.addSubview(bubbleXField)
        
        // 气泡框 Y 偏移
        let bubbleYLabel = NSTextField(labelWithString: "Y 偏移:")
        bubbleYLabel.sizeToFit()
        bubbleYLabel.frame.origin = CGPoint(x: 210, y: y)
        documentView.addSubview(bubbleYLabel)
        
        let bubbleYField = NSTextField(frame: NSRect(x: 280, y: y, width: 80, height: 22))
        bubbleYField.tag = 1005
        bubbleYField.stringValue = "\(Int(UserDefaults.standard.double(forKey: "bubbleOffsetY")))"
        documentView.addSubview(bubbleYField)
        
        y -= 45
        
        // AI 模型配置
        let aiLabel = NSTextField(labelWithString: "AI 模型配置")
        aiLabel.font = NSFont.systemFont(ofSize: 16, weight: .medium)
        aiLabel.textColor = .secondaryLabelColor
        aiLabel.sizeToFit()
        aiLabel.frame.origin = CGPoint(x: 20, y: y)
        documentView.addSubview(aiLabel)
        
        y -= 35
        
        // 提供商选择
        let providerLabel = NSTextField(labelWithString: "提供商:")
        providerLabel.sizeToFit()
        providerLabel.frame.origin = CGPoint(x: 40, y: y)
        documentView.addSubview(providerLabel)
        
        let providerPopUp = NSPopUpButton(frame: NSRect(x: 120, y: y, width: 200, height: 25))
        providerPopUp.tag = 1006
        providerPopUp.addItems(withTitles: ["OpenAI", "Anthropic Claude", "OpenClaw Gateway"])
        documentView.addSubview(providerPopUp)
        
        y -= 35
        
        // OpenClaw 路径设置
        let pathLabel = NSTextField(labelWithString: "OpenClaw 路径:")
        pathLabel.sizeToFit()
        pathLabel.frame.origin = CGPoint(x: 40, y: y)
        documentView.addSubview(pathLabel)
        
        let pathField = NSTextField(frame: NSRect(x: 160, y: y, width: 250, height: 22))
        pathField.tag = 1007
        pathField.stringValue = AppConfiguration.openclawPath
        documentView.addSubview(pathField)
        
        y -= 45
        
        // Agent 选择
        let agentLabel = NSTextField(labelWithString: "Agent 选择 (\(viewModel.availableAgents.count)个可用)")
        agentLabel.font = NSFont.systemFont(ofSize: 16, weight: .medium)
        agentLabel.textColor = .secondaryLabelColor
        agentLabel.sizeToFit()
        agentLabel.frame.origin = CGPoint(x: 20, y: y)
        documentView.addSubview(agentLabel)
        
        y -= 35
        
        // Agent 单选按钮
        for (index, agent) in viewModel.availableAgents.enumerated() {
            let button = NSButton(frame: NSRect(x: 40, y: y, width: 400, height: 24))
            button.title = "\(agent.icon) \(agent.name) - \(agent.description)"
            button.setButtonType(.radio)
            button.state = agent.id == viewModel.currentAgent.id ? .on : .off
            button.tag = 2000 + index
            button.target = self
            button.action = #selector(agentSelected(_:))
            documentView.addSubview(button)
            y -= 28
        }
        
        y -= 20
        
        // 调整文档视图高度
        let actualHeight = contentHeight - y + 50
        documentView.frame = NSRect(x: 0, y: 0, width: 460, height: actualHeight)
        
        // 设置文档视图
        scrollView.documentView = documentView
        
        // 滚动到顶部
        scrollView.contentView.scroll(to: NSPoint(x: 0, y: actualHeight - scrollView.contentView.bounds.height))
        
        // 创建容器视图
        let containerView = NSView(frame: NSRect(x: 0, y: 0, width: 480, height: windowHeight))
        containerView.autoresizingMask = [.width, .height]
        containerView.addSubview(scrollView)
        
        // 完成按钮（固定在底部）
        let doneButton = NSButton(frame: NSRect(x: 380, y: 10, width: 80, height: 28))
        doneButton.title = "完成"
        doneButton.bezelStyle = .rounded
        doneButton.keyEquivalent = "\r"
        doneButton.target = self
        doneButton.action = #selector(closeSettings(_:))
        doneButton.autoresizingMask = [.minXMargin, .maxYMargin]
        containerView.addSubview(doneButton)
        
        window.contentView = containerView
        
        self.window = window
        showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc private func agentSelected(_ sender: NSButton) {
        let index = sender.tag - 2000
        guard index >= 0 && index < viewModel.availableAgents.count else { return }
        viewModel.switchAgent(viewModel.availableAgents[index])
    }
    
    @objc private func closeSettings(_ sender: NSButton) {
        guard let window = self.window,
              let scrollView = window.contentView?.subviews.first(where: { $0 is NSScrollView }) as? NSScrollView,
              let documentView = scrollView.documentView else {
            window?.close()
            return
        }
        
        // 保存所有设置
        for view in documentView.subviews {
            if let popUp = view as? NSPopUpButton {
                switch popUp.tag {
                case 1001: // 自动消失时间
                    let times: [Double] = [5, 10, 15, 30, -1]
                    UserDefaults.standard.set(times[popUp.indexOfSelectedItem], forKey: "bubbleAutoHideSeconds")
                default: break
                }
            } else if let textField = view as? NSTextField {
                switch textField.tag {
                case 1002: // Pet X
                    if let val = Double(textField.stringValue) {
                        UserDefaults.standard.set(val, forKey: "petInitialX")
                    }
                case 1003: // Pet Y
                    if let val = Double(textField.stringValue) {
                        UserDefaults.standard.set(val, forKey: "petInitialY")
                    }
                case 1004: // 气泡 X 偏移
                    if let val = Double(textField.stringValue) {
                        UserDefaults.standard.set(val, forKey: "bubbleOffsetX")
                    }
                case 1005: // 气泡 Y 偏移
                    if let val = Double(textField.stringValue) {
                        UserDefaults.standard.set(val, forKey: "bubbleOffsetY")
                    }
                case 1007: // OpenClaw 路径
                    AppConfiguration.openclawPath = textField.stringValue
                default: break
                }
            }
        }
        
        window.close()
        SettingsWindowController.shared = nil
    }
}
