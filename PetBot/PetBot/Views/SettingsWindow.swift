// SettingsWindow.swift
// 设置窗口 - 带滚动条

import Cocoa

class SettingsWindowController: NSWindowController {
    static var shared: SettingsWindowController?
    
    private var viewModel: AgentViewModel!
    
    override init(window: NSWindow?) {
        super.init(window: window)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func setup(with viewModel: AgentViewModel) {
        self.viewModel = viewModel
    }
    
    func showSettings() {
        SettingsWindowController.shared = self
        
        // 计算内容高度（根据 agent 数量）
        let agentCount = viewModel.availableAgents.count
        let contentHeight: CGFloat = 620 + CGFloat(agentCount * 35)  // 增加基础高度
        // 窗口高度最小 500，最大 700，确保有足够空间滚动
        let windowHeight: CGFloat = min(700, max(500, contentHeight))
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: windowHeight),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "PetBot 设置"
        window.center()
        // 减小最小高度限制，允许更灵活的窗口大小
        window.minSize = NSSize(width: 480, height: 400)
        
        // 创建滚动视图 - 留出底部50px给完成按钮
        let scrollView = NSScrollView(frame: NSRect(x: 0, y: 50, width: 480, height: windowHeight - 50))
        scrollView.autoresizingMask = [.width, .height]
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = false  // 始终显示滚动条
        scrollView.borderType = .noBorder
        scrollView.backgroundColor = .clear
        
        // 创建文档视图（内容容器）- 使用预估高度
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
        
        // 聊天记录设置
        let chatHistoryLabel = NSTextField(labelWithString: "聊天记录设置")
        chatHistoryLabel.font = NSFont.systemFont(ofSize: 16, weight: .medium)
        chatHistoryLabel.textColor = .secondaryLabelColor
        chatHistoryLabel.sizeToFit()
        chatHistoryLabel.frame.origin = CGPoint(x: 20, y: y)
        documentView.addSubview(chatHistoryLabel)
        
        y -= 35
        
        // 保存时长
        let retentionLabel = NSTextField(labelWithString: "保存时长:")
        retentionLabel.sizeToFit()
        retentionLabel.frame.origin = CGPoint(x: 40, y: y)
        documentView.addSubview(retentionLabel)
        
        let retentionPopUp = NSPopUpButton(frame: NSRect(x: 120, y: y, width: 150, height: 25))
        retentionPopUp.tag = 1013
        retentionPopUp.addItems(withTitles: ["1小时", "6小时", "12小时", "24小时", "3天", "7天", "永久"])
        let currentHours = AppConfiguration.chatHistoryRetentionHours
        let retentionOptions = [1, 6, 12, 24, 72, 168, -1]
        if let index = retentionOptions.firstIndex(of: currentHours) {
            retentionPopUp.selectItem(at: index)
        } else {
            retentionPopUp.selectItem(at: 3) // 默认24小时
        }
        documentView.addSubview(retentionPopUp)
        
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
        
        // Pet UI 设置
        let petUILabel = NSTextField(labelWithString: "Pet UI 设置")
        petUILabel.font = NSFont.systemFont(ofSize: 16, weight: .medium)
        petUILabel.textColor = .secondaryLabelColor
        petUILabel.sizeToFit()
        petUILabel.frame.origin = CGPoint(x: 20, y: y)
        documentView.addSubview(petUILabel)
        
        y -= 35
        
        // 图片路径
        let imagePathLabel = NSTextField(labelWithString: "图片路径:")
        imagePathLabel.sizeToFit()
        imagePathLabel.frame.origin = CGPoint(x: 40, y: y)
        documentView.addSubview(imagePathLabel)
        
        let imagePathField = NSTextField(frame: NSRect(x: 120, y: y, width: 290, height: 22))
        imagePathField.tag = 1008
        imagePathField.stringValue = AppConfiguration.petImagePath
        documentView.addSubview(imagePathField)
        
        y -= 35
        
        // 最大高度
        let maxHeightLabel = NSTextField(labelWithString: "最大高度(px):")
        maxHeightLabel.sizeToFit()
        maxHeightLabel.frame.origin = CGPoint(x: 40, y: y)
        documentView.addSubview(maxHeightLabel)
        
        let maxHeightField = NSTextField(frame: NSRect(x: 140, y: y, width: 80, height: 22))
        maxHeightField.tag = 1009
        maxHeightField.stringValue = "\(Int(AppConfiguration.petMaxHeight))"
        documentView.addSubview(maxHeightField)
        
        let hintLabel = NSTextField(labelWithString: "(图片将缩放至此高度)")
        hintLabel.font = NSFont.systemFont(ofSize: 11)
        hintLabel.textColor = .secondaryLabelColor
        hintLabel.sizeToFit()
        hintLabel.frame.origin = CGPoint(x: 230, y: y)
        documentView.addSubview(hintLabel)
        
        y -= 45
        
        // 输入框位置设置
        let inputPosLabel = NSTextField(labelWithString: "输入框位置")
        inputPosLabel.font = NSFont.systemFont(ofSize: 16, weight: .medium)
        inputPosLabel.textColor = .secondaryLabelColor
        inputPosLabel.sizeToFit()
        inputPosLabel.frame.origin = CGPoint(x: 20, y: y)
        documentView.addSubview(inputPosLabel)
        
        y -= 35
        
        // 输入框 X 位置
        let inputXLabel = NSTextField(labelWithString: "X:")
        inputXLabel.sizeToFit()
        inputXLabel.frame.origin = CGPoint(x: 40, y: y)
        documentView.addSubview(inputXLabel)
        
        let inputXField = NSTextField(frame: NSRect(x: 70, y: y, width: 80, height: 22))
        inputXField.tag = 1011
        let inputX = AppConfiguration.inputInitialX
        inputXField.stringValue = inputX < 0 ? "" : "\(Int(inputX))"
        inputXField.placeholderString = "居中"
        documentView.addSubview(inputXField)
        
        // 输入框 Y 位置
        let inputYLabel = NSTextField(labelWithString: "Y:")
        inputYLabel.sizeToFit()
        inputYLabel.frame.origin = CGPoint(x: 170, y: y)
        documentView.addSubview(inputYLabel)
        
        let inputYField = NSTextField(frame: NSRect(x: 200, y: y, width: 80, height: 22))
        inputYField.tag = 1012
        let inputY = AppConfiguration.inputInitialY
        inputYField.stringValue = inputY < 0 ? "" : "\(Int(inputY))"
        inputYField.placeholderString = "居中"
        documentView.addSubview(inputYField)
        
        let inputHintLabel = NSTextField(labelWithString: "(留空则居中显示)")
        inputHintLabel.font = NSFont.systemFont(ofSize: 11)
        inputHintLabel.textColor = .secondaryLabelColor
        inputHintLabel.sizeToFit()
        inputHintLabel.frame.origin = CGPoint(x: 290, y: y)
        documentView.addSubview(inputHintLabel)
        
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
        
        // 调整文档视图高度 - 确保包含所有内容
        let actualHeight = max(contentHeight - y + 50, windowHeight - 50)
        documentView.frame = NSRect(x: 0, y: 0, width: 460, height: actualHeight)
        
        // 设置文档视图
        scrollView.documentView = documentView
        
        // 确保滚动条刷新
        scrollView.needsLayout = true
        scrollView.needsDisplay = true
        
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
                case 1013: // 聊天记录保存时长
                    let hours = [1, 6, 12, 24, 72, 168, -1]
                    AppConfiguration.chatHistoryRetentionHours = hours[popUp.indexOfSelectedItem]
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
                case 1008: // Pet 图片路径
                    AppConfiguration.petImagePath = textField.stringValue
                case 1009: // Pet 最大高度
                    if let val = Double(textField.stringValue), val > 0 {
                        AppConfiguration.petMaxHeight = val
                    }
                case 1011: // 输入框 X 位置
                    if let val = Double(textField.stringValue), val > 0 {
                        AppConfiguration.inputInitialX = val
                    } else {
                        AppConfiguration.inputInitialX = -1
                    }
                case 1012: // 输入框 Y 位置
                    if let val = Double(textField.stringValue), val > 0 {
                        AppConfiguration.inputInitialY = val
                    } else {
                        AppConfiguration.inputInitialY = -1
                    }
                default: break
                }
            }
        }
        
        window.close()
        SettingsWindowController.shared = nil
    }
}
