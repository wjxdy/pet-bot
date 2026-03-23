// ChatHistoryWindow.swift
// 聊天历史窗口 - 像素 RPG 风格

import Cocoa
import WebKit

@MainActor
class ChatHistoryWindow: NSWindow {
    private var viewModel: AgentViewModel
    private var markdownWebView: MarkdownWebView?
    private var tableView: NSTableView!
    private var splitView: NSSplitView!
    private var leftBackgroundView: PixelBackgroundView!
    private var titleLabel: NSTextField!
    
    // 当前显示的Agent ID
    private var displayedAgentId: String {
        return viewModel.currentAgent.id
    }
    
    init(viewModel: AgentViewModel) {
        self.viewModel = viewModel
        
        super.init(
            contentRect: NSRect(x: 100, y: 100, width: 900, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        self.title = "📜 冒险者公会 - 聊天历史"
        self.minSize = NSSize(width: 700, height: 500)
        
        // 设置窗口关闭时不释放
        self.isReleasedWhenClosed = false
        self.delegate = self
        
        setupPixelUI()
        self.center()
    }
    
    private func setupPixelUI() {
        // 创建主背景视图
        let mainBackground = PixelBackgroundView(frame: contentView!.bounds)
        mainBackground.autoresizingMask = [.width, .height]
        contentView?.addSubview(mainBackground)
        
        // 创建像素风格的分割视图
        splitView = NSSplitView()
        splitView.isVertical = true
        splitView.dividerStyle = .thick
        splitView.autoresizingMask = [.width, .height]
        splitView.frame = NSRect(x: 16, y: 16, width: contentView!.bounds.width - 32, height: contentView!.bounds.height - 32)
        
        // MARK: - 左侧 Agent 列表面板
        let leftPanel = PixelPanelView(frame: NSRect(x: 0, y: 0, width: 220, height: splitView.bounds.height))
        leftPanel.title = "同伴列表"
        
        // 创建滚动视图
        let leftScrollView = NSScrollView(frame: NSRect(x: 8, y: 40, width: 204, height: leftPanel.bounds.height - 48))
        leftScrollView.hasVerticalScroller = true
        leftScrollView.autohidesScrollers = true
        leftScrollView.backgroundColor = NSColor(red: 0.95, green: 0.9, blue: 0.8, alpha: 1.0)
        leftScrollView.drawsBackground = true
        
        // 配置表格视图
        tableView = NSTableView()
        tableView.headerView = nil
        // 禁用默认蓝色高亮，完全由自定义 cell 控制选中效果
        tableView.selectionHighlightStyle = .none
        tableView.allowsEmptySelection = false
        tableView.allowsMultipleSelection = false
        tableView.backgroundColor = NSColor(red: 0.95, green: 0.9, blue: 0.8, alpha: 1.0)
        tableView.intercellSpacing = NSSize(width: 0, height: 4)
        tableView.rowHeight = 40
        tableView.usesAlternatingRowBackgroundColors = false
        tableView.focusRingType = .none
        
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("AgentColumn"))
        column.minWidth = 180
        column.maxWidth = 204
        column.isEditable = false
        tableView.addTableColumn(column)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.target = self
        tableView.action = #selector(tableViewClicked(_:))
        
        // 监听 Agent 变化通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(agentDidChange(_:)),
            name: NSNotification.Name("AgentDidChange"),
            object: nil
        )
        
        updateTableViewSelection()
        
        leftScrollView.documentView = tableView
        leftPanel.addSubview(leftScrollView)
        splitView.addSubview(leftPanel)
        
        // MARK: - 右侧聊天面板
        let rightPanel = PixelPanelView(frame: NSRect(x: 0, y: 0, width: splitView.bounds.width - 220, height: splitView.bounds.height))
        rightPanel.title = "对话记录"
        
        // 创建 Markdown WebView
        let markdownView = MarkdownWebView(frame: NSRect(x: 8, y: 40, width: rightPanel.bounds.width - 16, height: rightPanel.bounds.height - 48))
        markdownView.autoresizingMask = [.width, .height]
        rightPanel.addSubview(markdownView)
        markdownWebView = markdownView
        
        splitView.addSubview(rightPanel)
        mainBackground.addSubview(splitView)
        
        // 设置分割位置
        DispatchQueue.main.async { [weak self] in
            self?.splitView.setPosition(220, ofDividerAt: 0)
        }
        
        loadChatHistory()
    }
    
    private func loadChatHistory() {
        let storedMessages = ChatHistoryStorage.shared.getMessages(for: viewModel.currentAgent.id)
        let allMessages = storedMessages + viewModel.messages
        
        var markdownContent = buildRPGHeader(title: "与 \(viewModel.currentAgent.name) 的对话")
        
        guard !allMessages.isEmpty else {
            markdownContent += "\n*暂无对话记录...*\n"
            markdownWebView?.renderMarkdown(markdownContent)
            return
        }
        
        for message in allMessages {
            if message.isUser {
                // 玩家消息 - 使用 Markdown 引用格式（右对齐用 HTML 包裹）
                markdownContent += "\n<div style='text-align: right; margin: 8px 0;'>\n"
                markdownContent += "<span style='background: #4A90E2; color: white; padding: 6px 12px; border-radius: 4px; display: inline-block; font-family: monospace;'>\n"
                markdownContent += "\n" + message.content + "\n"
                markdownContent += "</span>\n"
                markdownContent += "<span style='font-size: 12px; color: #666; margin-left: 8px;'>⚔️ 你</span>\n"
                markdownContent += "</div>\n"
            } else {
                // Agent 消息
                markdownContent += "\n<div style='text-align: left; margin: 8px 0;'>\n"
                markdownContent += "<span style='font-size: 12px; color: #666;'>🛡️ \(message.agentName ?? "Agent")</span>\n"
                markdownContent += "<span style='background: #7ED321; color: #1a3d0a; padding: 6px 12px; border-radius: 4px; display: inline-block; font-family: monospace; border: 2px solid #5a9c1c; margin-left: 4px;'>\n"
                markdownContent += "\n" + message.content + "\n"
                markdownContent += "</span>\n"
                markdownContent += "</div>\n"
            }
        }
        
        markdownContent += "\n---\n*对话结束* 🏁\n"
        markdownWebView?.renderMarkdown(markdownContent)
    }
    
    private func buildRPGHeader(title: String) -> String {
        var header = "<div style='text-align: center; margin-bottom: 20px;'>\n"
        header += "<h2 style='font-family: monospace; color: #8B4513; text-shadow: 2px 2px 0px #D2691E; margin: 0;'>\n"
        header += "╔════════════════════════════════╗<br>\n"
        header += "║  \(title)  ║<br>\n"
        header += "╚════════════════════════════════╝\n"
        header += "</h2></div>\n\n"
        return header
    }
    
    private func escapeHTML(_ text: String) -> String {
        return text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
    
    private func updateTableViewSelection() {
        // 找到当前 Agent 的索引
        if let index = viewModel.availableAgents.firstIndex(where: { $0.id == viewModel.currentAgent.id }) {
            // 避免重复选择导致跳动
            if tableView.selectedRow != index {
                tableView.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
            }
        }
    }
    
    @objc private func agentDidChange(_ notification: Notification) {
        // 如果通知是这个窗口自己发送的（object是ChatHistoryWindow且是self），跳过
        // 如果object是Agent或其他类型，则继续处理（可能是其他窗口或主界面发送的）
        if let senderWindow = notification.object as? ChatHistoryWindow, senderWindow === self {
            return
        }
        
        // 收到通知后更新选择状态
        DispatchQueue.main.async { [weak self] in
            self?.updateTableViewSelection()
            // 只刷新单元格外观，不改变选中状态
            self?.tableView.reloadData()
        }
    }
    
    func appendMessage(_ text: String, isUser: Bool, forAgentId agentId: String) {
        guard agentId == displayedAgentId else { return }
        
        // 使用 MarkdownRenderer 构建消息，确保 UTF-8 编码正确
        var messageMarkdown = "\n"
        if isUser {
            messageMarkdown += "<div style='text-align: right; margin: 8px 0;'>\n"
            messageMarkdown += "<span style='background: #4A90E2; color: white; padding: 6px 12px; border-radius: 4px; display: inline-block; font-family: monospace;'>\n\n"
            messageMarkdown += text
            messageMarkdown += "\n</span>\n"
            messageMarkdown += "<span style='font-size: 12px; color: #666; margin-left: 8px;'>⚔️ 你</span>\n"
            messageMarkdown += "</div>\n"
        } else {
            messageMarkdown += "<div style='text-align: left; margin: 8px 0;'>\n"
            messageMarkdown += "<span style='font-size: 12px; color: #666;'>🛡️ \(viewModel.currentAgent.name)</span>\n"
            messageMarkdown += "<span style='background: #7ED321; color: #1a3d0a; padding: 6px 12px; border-radius: 4px; display: inline-block; font-family: monospace; border: 2px solid #5a9c1c; margin-left: 4px;'>\n\n"
            messageMarkdown += text
            messageMarkdown += "\n</span>\n"
            messageMarkdown += "</div>\n"
        }
        
        // 使用 renderMarkdown 而不是 appendHTML，确保正确编码
        markdownWebView?.appendMarkdown(messageMarkdown)
    }
}

// MARK: - NSTableViewDataSource & Delegate
extension ChatHistoryWindow: NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return viewModel.availableAgents.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard row < viewModel.availableAgents.count else { return nil }
        
        let agent = viewModel.availableAgents[row]
        let isSelected = agent.id == viewModel.currentAgent.id
        
        let cell = PixelAgentCell(frame: NSRect(x: 0, y: 0, width: 200, height: 36))
        cell.configure(agent: agent, isSelected: isSelected)
        return cell
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 40
    }
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return true
    }
    
    @objc func tableViewClicked(_ sender: NSTableView) {
        let clickedRow = sender.clickedRow
        guard clickedRow >= 0 && clickedRow < viewModel.availableAgents.count else { return }
        
        let selectedAgent = viewModel.availableAgents[clickedRow]
        
        // 如果点击的是已选中的，不做任何事
        guard selectedAgent.id != viewModel.currentAgent.id else { return }
        
        // 更新当前 Agent
        viewModel.currentAgent = selectedAgent
        self.title = "📜 冒险者公会 - 与 \(selectedAgent.name) 的对话"
        
        // 先刷新所有单元格的外观（这可能会重置选中状态）
        sender.reloadData()
        
        // 然后再设置正确的选中状态
        updateTableViewSelection()
        
        // 加载新的历史记录
        loadChatHistory()
        
        // 通知其他窗口 - 传入self以便识别发送者
        NotificationCenter.default.post(name: NSNotification.Name("AgentDidChange"), object: self)
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        // 使用 tableViewClicked 处理，这里不做任何事
    }
}

// MARK: - NSWindowDelegate
extension ChatHistoryWindow: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        ChatHistoryManager.currentWindow = nil
    }
}

// MARK: - 像素风格背景视图
class PixelBackgroundView: NSView {
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        
        // 绘制复古游戏背景色
        let bgColor = CGColor(red: 0.15, green: 0.12, blue: 0.08, alpha: 1.0)
        context.setFillColor(bgColor)
        context.fill(bounds)
        
        // 绘制像素边框装饰
        drawPixelBorder(context, rect: bounds.insetBy(dx: 4, dy: 4))
    }
    
    private func drawPixelBorder(_ context: CGContext, rect: CGRect) {
        let borderColor = CGColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 1.0)
        let cornerColor = CGColor(red: 0.8, green: 0.6, blue: 0.3, alpha: 1.0)
        
        context.setLineWidth(4)
        
        // 绘制双线边框
        context.setStrokeColor(cornerColor)
        let outerRect = rect.insetBy(dx: 2, dy: 2)
        context.stroke(outerRect)
        
        context.setStrokeColor(borderColor)
        let innerRect = rect.insetBy(dx: 6, dy: 6)
        context.stroke(innerRect)
        
        // 绘制角落装饰
        let cornerSize: CGFloat = 16
        context.setFillColor(cornerColor)
        
        // 左上角
        context.fill(CGRect(x: rect.minX, y: rect.maxY - cornerSize, width: cornerSize, height: cornerSize))
        // 右上角
        context.fill(CGRect(x: rect.maxX - cornerSize, y: rect.maxY - cornerSize, width: cornerSize, height: cornerSize))
        // 左下角
        context.fill(CGRect(x: rect.minX, y: rect.minY, width: cornerSize, height: cornerSize))
        // 右下角
        context.fill(CGRect(x: rect.maxX - cornerSize, y: rect.minY, width: cornerSize, height: cornerSize))
    }
}

// MARK: - 像素风格面板
class PixelPanelView: NSView {
    var title: String = "" {
        didSet {
            titleLabel?.stringValue = title
        }
    }
    private var titleLabel: NSTextField!
    
    override init(frame: NSRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        // 背景色 - 羊皮纸风格
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor(red: 0.95, green: 0.9, blue: 0.8, alpha: 1.0).cgColor
        
        // 标题栏
        let titleBar = NSView(frame: NSRect(x: 0, y: bounds.height - 32, width: bounds.width, height: 32))
        titleBar.wantsLayer = true
        titleBar.layer?.backgroundColor = NSColor(red: 0.4, green: 0.25, blue: 0.15, alpha: 1.0).cgColor
        titleBar.autoresizingMask = [.width, .minYMargin]
        addSubview(titleBar)
        
        // 标题文字
        titleLabel = NSTextField(labelWithString: title)
        titleLabel.frame = NSRect(x: 8, y: 6, width: bounds.width - 16, height: 20)
        titleLabel.font = NSFont(name: "Courier", size: 14) ?? NSFont.boldSystemFont(ofSize: 14)
        titleLabel.textColor = NSColor(red: 1.0, green: 0.9, blue: 0.7, alpha: 1.0)
        titleLabel.alignment = .center
        titleLabel.autoresizingMask = [.width]
        titleBar.addSubview(titleLabel)
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        
        // 绘制像素边框
        let borderColor = CGColor(red: 0.4, green: 0.25, blue: 0.15, alpha: 1.0)
        context.setStrokeColor(borderColor)
        context.setLineWidth(4)
        context.stroke(bounds.insetBy(dx: 2, dy: 2))
        
        // 绘制内边框
        context.setLineWidth(2)
        context.stroke(bounds.insetBy(dx: 6, dy: 6))
    }
}

// MARK: - 像素风格 Agent 单元格
class PixelAgentCell: NSView {
    private var iconLabel: NSTextField!
    private var nameLabel: NSTextField!
    private var pressedBackground: NSView!
    private var isSelected: Bool = false
    
    override init(frame: NSRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        self.wantsLayer = true
        
        // 选中状态的半透明高亮背景 - 琥珀金色，与羊皮纸风格搭配
        pressedBackground = NSView(frame: bounds)
        pressedBackground.wantsLayer = true
        // 使用半透明的琥珀金色，既明显又不突兀
        pressedBackground.layer?.backgroundColor = NSColor(red: 0.85, green: 0.70, blue: 0.40, alpha: 0.35).cgColor
        // 添加轻微圆角让过渡更柔和
        pressedBackground.layer?.cornerRadius = 4
        pressedBackground.isHidden = true
        pressedBackground.autoresizingMask = [.width, .height]
        addSubview(pressedBackground)
        
        // 选中时的边框装饰 - 像素风格的内边框
        let innerBorder = NSView(frame: bounds.insetBy(dx: 3, dy: 3))
        innerBorder.wantsLayer = true
        innerBorder.layer?.borderWidth = 2
        // 边框使用更深的琥珀色，半透明显示层次感
        innerBorder.layer?.borderColor = NSColor(red: 0.75, green: 0.55, blue: 0.25, alpha: 0.60).cgColor
        innerBorder.layer?.cornerRadius = 2
        innerBorder.isHidden = true
        innerBorder.autoresizingMask = [.width, .height]
        pressedBackground.addSubview(innerBorder)
        
        // 图标
        iconLabel = NSTextField(labelWithString: "🤖")
        iconLabel.frame = NSRect(x: 16, y: 8, width: 24, height: 20)
        iconLabel.font = NSFont.systemFont(ofSize: 16)
        iconLabel.alignment = .center
        iconLabel.isEditable = false
        iconLabel.isSelectable = false
        iconLabel.backgroundColor = .clear
        addSubview(iconLabel)
        
        // 名称
        nameLabel = NSTextField(labelWithString: "Agent")
        nameLabel.frame = NSRect(x: 44, y: 10, width: bounds.width - 52, height: 16)
        nameLabel.font = NSFont(name: "Courier", size: 13) ?? NSFont.systemFont(ofSize: 13, weight: .medium)
        nameLabel.textColor = NSColor(red: 0.2, green: 0.15, blue: 0.1, alpha: 1.0)
        nameLabel.autoresizingMask = [.width]
        nameLabel.isEditable = false
        nameLabel.isSelectable = false
        nameLabel.backgroundColor = .clear
        addSubview(nameLabel)
    }
    
    func configure(agent: Agent, isSelected: Bool) {
        self.isSelected = isSelected
        iconLabel.stringValue = agent.icon.isEmpty ? "🤖" : agent.icon
        nameLabel.stringValue = agent.name
        
        if isSelected {
            // 选中状态：半透明琥珀高亮
            pressedBackground.isHidden = false
            // 文字稍微向右下偏移，模拟按下
            iconLabel.frame.origin.x = 18
            iconLabel.frame.origin.y = 6
            nameLabel.frame.origin.x = 46
            nameLabel.frame.origin.y = 8
            nameLabel.font = NSFont(name: "Courier-Bold", size: 13) ?? NSFont.boldSystemFont(ofSize: 13)
            // 使用深琥珀色文字，与半透明背景形成良好对比
            nameLabel.textColor = NSColor(red: 0.55, green: 0.35, blue: 0.10, alpha: 1.0)
        } else {
            // 未选中状态：正常
            pressedBackground.isHidden = true
            // 文字复位
            iconLabel.frame.origin.x = 16
            iconLabel.frame.origin.y = 8
            nameLabel.frame.origin.x = 44
            nameLabel.frame.origin.y = 10
            nameLabel.font = NSFont(name: "Courier", size: 13) ?? NSFont.systemFont(ofSize: 13)
            nameLabel.textColor = NSColor(red: 0.2, green: 0.15, blue: 0.1, alpha: 1.0)
        }
    }
    
    // 让点击事件传递给 tableView
    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        
        if !isSelected {
            // 未选中时绘制底部分隔线
            context.setStrokeColor(CGColor(red: 0.7, green: 0.6, blue: 0.5, alpha: 0.5))
            context.setLineWidth(2)
            context.move(to: CGPoint(x: 8, y: 0))
            context.addLine(to: CGPoint(x: bounds.width - 8, y: 0))
            context.strokePath()
        }
    }
}

@MainActor
class ChatHistoryManager {
    static var currentWindow: ChatHistoryWindow?
    
    static func show(viewModel: AgentViewModel) {
        if currentWindow == nil {
            currentWindow = ChatHistoryWindow(viewModel: viewModel)
        }
        
        if currentWindow?.windowNumber == -1 {
            currentWindow = ChatHistoryWindow(viewModel: viewModel)
        }
        
        currentWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    static func hide() {
        currentWindow?.orderOut(nil)
    }
    
    static func close() {
        currentWindow?.close()
    }
}
