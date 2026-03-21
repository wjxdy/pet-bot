// SettingsView.swift
// 设置窗口 - 原生 AppKit 实现

import Cocoa

class SettingsWindowController: NSWindowController {
    static let shared = SettingsWindowController()
    
    private var viewModel: AgentViewModel!
    
    // UI 控件
    private var autoHideTimePopUp: NSPopUpButton!
    private var offsetXSlider: NSSlider!
    private var offsetYSlider: NSSlider!
    private var offsetXLabel: NSTextField!
    private var offsetYLabel: NSTextField!
    private var agentButtons: [NSButton] = []
    
    // 初始化
    func setup(with viewModel: AgentViewModel) {
        self.viewModel = viewModel
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 500),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "PetBot 设置"
        window.isReleasedWhenClosed = false
        window.center()
        
        self.window = window
        setupUI()
        loadSettings()
    }
    
    private func setupUI() {
        guard let contentView = window?.contentView else { return }
        
        let scrollView = NSScrollView(frame: contentView.bounds)
        scrollView.autoresizingMask = [.width, .height]
        scrollView.hasVerticalScroller = true
        contentView.addSubview(scrollView)
        
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 480, height: 600))
        scrollView.documentView = container
        
        var y: CGFloat = 550
        
        // 标题
        let title = NSTextField(labelWithString: "PetBot 设置")
        title.font = NSFont.systemFont(ofSize: 20, weight: .semibold)
        title.sizeToFit()
        title.frame.origin = CGPoint(x: 20, y: y)
        container.addSubview(title)
        
        y -= 60
        
        // 气泡设置
        let bubbleLabel = NSTextField(labelWithString: "气泡设置")
        bubbleLabel.font = NSFont.systemFont(ofSize: 16, weight: .medium)
        bubbleLabel.textColor = .secondaryLabelColor
        bubbleLabel.sizeToFit()
        bubbleLabel.frame.origin = CGPoint(x: 20, y: y)
        container.addSubview(bubbleLabel)
        
        y -= 40
        
        // 自动消失时间
        let timeLabel = NSTextField(labelWithString: "自动消失时间:")
        timeLabel.sizeToFit()
        timeLabel.frame.origin = CGPoint(x: 40, y: y)
        container.addSubview(timeLabel)
        
        autoHideTimePopUp = NSPopUpButton(frame: NSRect(x: 160, y: y, width: 150, height: 25))
        autoHideTimePopUp.addItems(withTitles: ["5秒", "10秒", "15秒", "30秒", "永不"])
        autoHideTimePopUp.target = self
        autoHideTimePopUp.action = #selector(timeChanged(_:))
        container.addSubview(autoHideTimePopUp)
        
        y -= 45
        
        // X 偏移
        let xLabel = NSTextField(labelWithString: "X 偏移:")
        xLabel.sizeToFit()
        xLabel.frame.origin = CGPoint(x: 40, y: y)
        container.addSubview(xLabel)
        
        offsetXLabel = NSTextField(labelWithString: "0")
        offsetXLabel.frame = NSRect(x: 100, y: y, width: 30, height: 20)
        container.addSubview(offsetXLabel)
        
        offsetXSlider = NSSlider(frame: NSRect(x: 140, y: y, width: 250, height: 20))
        offsetXSlider.minValue = -100
        offsetXSlider.maxValue = 100
        offsetXSlider.target = self
        offsetXSlider.action = #selector(xChanged(_:))
        container.addSubview(offsetXSlider)
        
        y -= 45
        
        // Y 偏移
        let yLabel = NSTextField(labelWithString: "Y 偏移:")
        yLabel.sizeToFit()
        yLabel.frame.origin = CGPoint(x: 40, y: y)
        container.addSubview(yLabel)
        
        offsetYLabel = NSTextField(labelWithString: "0")
        offsetYLabel.frame = NSRect(x: 100, y: y, width: 30, height: 20)
        container.addSubview(offsetYLabel)
        
        offsetYSlider = NSSlider(frame: NSRect(x: 140, y: y, width: 250, height: 20))
        offsetYSlider.minValue = -50
        offsetYSlider.maxValue = 100
        offsetYSlider.target = self
        offsetYSlider.action = #selector(yChanged(_:))
        container.addSubview(offsetYSlider)
        
        y -= 60
        
        // Agent 选择
        let agentLabel = NSTextField(labelWithString: "Agent 选择")
        agentLabel.font = NSFont.systemFont(ofSize: 16, weight: .medium)
        agentLabel.textColor = .secondaryLabelColor
        agentLabel.sizeToFit()
        agentLabel.frame.origin = CGPoint(x: 20, y: y)
        container.addSubview(agentLabel)
        
        y -= 40
        
        // Agent 按钮
        for (index, agent) in viewModel.availableAgents.enumerated() {
            let button = NSButton(frame: NSRect(x: 40, y: y, width: 400, height: 24))
            button.title = "\(agent.icon) \(agent.name)"
            button.setButtonType(.radio)
            button.target = self
            button.action = #selector(agentChanged(_:))
            button.tag = index
            button.state = agent.id == viewModel.currentAgent.id ? .on : .off
            container.addSubview(button)
            agentButtons.append(button)
            y -= 30
        }
        
        // 完成按钮
        let doneButton = NSButton(frame: NSRect(x: 380, y: 20, width: 80, height: 28))
        doneButton.title = "完成"
        doneButton.bezelStyle = .rounded
        doneButton.keyEquivalent = "\r"
        doneButton.target = self
        doneButton.action = #selector(close)
        container.addSubview(doneButton)
    }
    
    private func loadSettings() {
        let times: [Double] = [5, 10, 15, 30, -1]
        let current = UserDefaults.standard.double(forKey: "bubbleAutoHideSeconds")
        if let index = times.firstIndex(of: current) {
            autoHideTimePopUp.selectItem(at: index)
        } else {
            autoHideTimePopUp.selectItem(at: 1) // 默认 10秒
        }
        
        let x = UserDefaults.standard.double(forKey: "bubbleOffsetX")
        let y = UserDefaults.standard.double(forKey: "bubbleOffsetY")
        offsetXSlider.doubleValue = x
        offsetYSlider.doubleValue = y
        offsetXLabel.stringValue = "\(Int(x))"
        offsetYLabel.stringValue = "\(Int(y))"
    }
    
    @objc private func timeChanged(_ sender: NSPopUpButton) {
        let times: [Double] = [5, 10, 15, 30, -1]
        UserDefaults.standard.set(times[sender.indexOfSelectedItem], forKey: "bubbleAutoHideSeconds")
    }
    
    @objc private func xChanged(_ sender: NSSlider) {
        let v = Int(sender.doubleValue)
        offsetXLabel.stringValue = "\(v)"
        UserDefaults.standard.set(sender.doubleValue, forKey: "bubbleOffsetX")
    }
    
    @objc private func yChanged(_ sender: NSSlider) {
        let v = Int(sender.doubleValue)
        offsetYLabel.stringValue = "\(v)"
        UserDefaults.standard.set(sender.doubleValue, forKey: "bubbleOffsetY")
    }
    
    @objc private func agentChanged(_ sender: NSButton) {
        let agents = viewModel.availableAgents
        guard sender.tag >= 0 && sender.tag < agents.count else { return }
        
        viewModel.switchAgent(agents[sender.tag])
        
        // 更新其他按钮
        for (i, btn) in agentButtons.enumerated() {
            btn.state = (i == sender.tag) ? .on : .off
        }
    }
    
    func showSettings() {
        if window == nil {
            setup(with: viewModel ?? AgentViewModel())
        }
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
