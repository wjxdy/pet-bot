// ChatHistoryWindow.swift
// 聊天历史窗口 - 类似 QQ 的消息列表 + 聊天窗口

import Cocoa

@MainActor
class ChatHistoryWindowController: NSWindowController {
    static var shared: ChatHistoryWindowController?
    
    private var viewModel: AgentViewModel!
    private var messageListView: NSTableView?
    private var chatTextView: NSTextView?
    private var inputTextField: NSTextField?
    private var selectedAgentId: String?
    
    // 存储每个 agent 的聊天记录
    private var chatHistories: [String: [ChatMessage]] = [:]
    
    func setup(with viewModel: AgentViewModel) {
        print("[ChatHistory] Setup called with viewModel")
        self.viewModel = viewModel
        loadChatHistories()
        print("[ChatHistory] Setup completed, agents count: \(viewModel.availableAgents.count)")
    }
    
    func showChatWindow() {
        print("[ChatHistory] showChatWindow called")
        ChatHistoryWindowController.shared = self
        
        // 检查 viewModel
        guard viewModel != nil else {
            print("[ChatHistory] ERROR: viewModel is nil!")
            return
        }
        
        if window == nil {
            print("[ChatHistory] Window is nil, creating...")
            createWindow()
        } else {
            print("[ChatHistory] Window already exists")
        }
        
        guard let window = window else {
            print("[ChatHistory] ERROR: Failed to create window!")
            return
        }
        
        print("[ChatHistory] Making window key and front...")
        window.makeKeyAndOrderFront(nil)
        
        print("[ChatHistory] Activating app...")
        let activated = NSApp.activate(ignoringOtherApps: true)
        print("[ChatHistory] App activation result: \(activated)")
        
        print("[ChatHistory] Window frame: \(window.frame)")
        print("[ChatHistory] Window isVisible: \(window.isVisible)")
        print("[ChatHistory] Window isKeyWindow: \(window.isKeyWindow)")
    }
    
    func addMessage(_ message: ChatMessage, for agentId: String) {
        if chatHistories[agentId] == nil {
            chatHistories[agentId] = []
        }
        chatHistories[agentId]?.append(message)
        
        // 如果当前选中的就是这个 agent，更新显示
        if selectedAgentId == agentId {
            appendMessageToChatView(message)
        }
        
        // 刷新侧边栏
        messageListView?.reloadData()
    }
    
    private func loadChatHistories() {
        // 初始化空的历史记录
        for agent in viewModel.availableAgents {
            if chatHistories[agent.id] == nil {
                chatHistories[agent.id] = []
            }
        }
    }
    
    private func createWindow() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "聊天记录"
        window.minSize = NSSize(width: 600, height: 400)
        
        // 主容器
        let splitView = NSSplitView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
        splitView.isVertical = true
        splitView.dividerStyle = .thin
        
        // 左侧 - Agent 列表
        let sidebarView = createSidebarView()
        sidebarView.frame = NSRect(x: 0, y: 0, width: 200, height: 600)
        
        // 右侧 - 聊天区域
        let chatView = createChatView()
        chatView.frame = NSRect(x: 200, y: 0, width: 600, height: 600)
        
        splitView.addSubview(sidebarView)
        splitView.addSubview(chatView)
        splitView.setPosition(200, ofDividerAt: 0)
        
        window.contentView = splitView
        self.window = window
        window.center()  // 窗口居中显示
    }
    
    private func createSidebarView() -> NSView {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        
        // 标题
        let titleLabel = NSTextField(labelWithString: "消息列表")
        titleLabel.font = NSFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.frame = NSRect(x: 16, y: 560, width: 168, height: 24)
        view.addSubview(titleLabel)
        
        // Agent 列表表格
        let scrollView = NSScrollView(frame: NSRect(x: 0, y: 50, width: 200, height: 550))
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        
        let tableView = NSTableView()
        tableView.headerView = nil
        tableView.rowHeight = 60
        tableView.selectionHighlightStyle = .regular
        tableView.delegate = self
        tableView.dataSource = self
        
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("agent"))
        column.width = 200
        tableView.addTableColumn(column)
        
        scrollView.documentView = tableView
        view.addSubview(scrollView)
        
        messageListView = tableView
        
        return view
    }
    
    private func createChatView() -> NSView {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        
        // 聊天标题
        let titleLabel = NSTextField(labelWithString: "选择 Agent 开始聊天")
        titleLabel.font = NSFont.systemFont(ofSize: 14, weight: .medium)
        titleLabel.alignment = .center
        titleLabel.frame = NSRect(x: 0, y: 570, width: 600, height: 24)
        view.addSubview(titleLabel)
        
        // 聊天内容区域（可滚动）
        let chatScrollView = NSScrollView(frame: NSRect(x: 16, y: 70, width: 568, height: 500))
        chatScrollView.hasVerticalScroller = true
        chatScrollView.autohidesScrollers = true
        chatScrollView.borderType = .noBorder
        
        let textView = NSTextView(frame: NSRect(x: 0, y: 0, width: 568, height: 500))
        textView.isEditable = false
        textView.isSelectable = true
        textView.backgroundColor = .clear
        textView.font = NSFont.systemFont(ofSize: 13)
        textView.textContainerInset = NSSize(width: 12, height: 12)
        
        chatScrollView.documentView = textView
        view.addSubview(chatScrollView)
        chatTextView = textView
        
        // 输入框区域
        let inputContainer = NSView(frame: NSRect(x: 16, y: 16, width: 568, height: 40))
        inputContainer.wantsLayer = true
        inputContainer.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        inputContainer.layer?.cornerRadius = 8
        
        let inputField = NSTextField(frame: NSRect(x: 12, y: 6, width: 480, height: 28))
        inputField.placeholderString = "输入消息..."
        inputField.target = self
        inputField.action = #selector(sendMessageFromChat)
        inputContainer.addSubview(inputField)
        inputTextField = inputField
        
        let sendButton = NSButton(frame: NSRect(x: 500, y: 6, width: 56, height: 28))
        sendButton.title = "发送"
        sendButton.bezelStyle = .rounded
        sendButton.target = self
        sendButton.action = #selector(sendMessageFromChat)
        inputContainer.addSubview(sendButton)
        
        view.addSubview(inputContainer)
        
        return view
    }
    
    @objc private func sendMessageFromChat() {
        guard let text = inputTextField?.stringValue.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty,
              let agentId = selectedAgentId else { return }
        
        // 添加用户消息
        let userMessage = ChatMessage(content: text, isUser: true, agentName: nil, timestamp: Date())
        addMessage(userMessage, for: agentId)
        
        inputTextField?.stringValue = ""
        
        // 发送给 agent
        Task {
            if let agent = viewModel.availableAgents.first(where: { $0.id == agentId }) {
                viewModel.switchAgent(agent)
                await viewModel.sendMessage(text)
                
                await MainActor.run {
                    if let lastMessage = viewModel.messages.last(where: { !$0.isUser }) {
                        let agentMessage = ChatMessage(content: lastMessage.content, isUser: false, agentName: agent.name, timestamp: Date())
                        addMessage(agentMessage, for: agentId)
                    }
                }
            }
        }
    }
    
    private func appendMessageToChatView(_ message: ChatMessage) {
        guard let textView = chatTextView else { return }
        
        let prefix = message.isUser ? "👤 你: " : "🤖 Agent: "
        let timeString = formatTime(message.timestamp)
        let formattedMessage = "\n[\(timeString)] \(prefix)\(message.content)\n"
        
        let attributedString = NSAttributedString(
            string: formattedMessage,
            attributes: [
                .font: NSFont.systemFont(ofSize: 13),
                .foregroundColor: message.isUser ? NSColor.controlAccentColor : NSColor.textColor
            ]
        )
        
        textView.textStorage?.append(attributedString)
        
        // 滚动到底部
        if let scrollView = textView.enclosingScrollView {
            let visibleRect = NSRect(x: 0, y: textView.bounds.maxY - scrollView.bounds.height, 
                                    width: scrollView.bounds.width, height: scrollView.bounds.height)
            textView.scrollToVisible(visibleRect)
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - NSTableView DataSource & Delegate
extension ChatHistoryWindowController: NSTableViewDataSource, NSTableViewDelegate {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return viewModel?.availableAgents.count ?? 0
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let agent = viewModel?.availableAgents[row] else { return nil }
        
        let cell = NSTableCellView()
        cell.frame = NSRect(x: 0, y: 0, width: 200, height: 60)
        
        // Agent 图标
        let iconLabel = NSTextField(labelWithString: agent.icon)
        iconLabel.font = NSFont.systemFont(ofSize: 24)
        iconLabel.frame = NSRect(x: 12, y: 16, width: 32, height: 32)
        cell.addSubview(iconLabel)
        
        // Agent 名称
        let nameLabel = NSTextField(labelWithString: agent.name)
        nameLabel.font = NSFont.systemFont(ofSize: 14, weight: .medium)
        nameLabel.frame = NSRect(x: 52, y: 28, width: 136, height: 20)
        cell.addSubview(nameLabel)
        
        // 最后一条消息预览
        if let lastMessage = chatHistories[agent.id]?.last {
            let previewLabel = NSTextField(labelWithString: String(lastMessage.content.prefix(20)) + "...")
            previewLabel.font = NSFont.systemFont(ofSize: 11)
            previewLabel.textColor = .secondaryLabelColor
            previewLabel.frame = NSRect(x: 52, y: 8, width: 136, height: 16)
            cell.addSubview(previewLabel)
        }
        
        return cell
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        guard let tableView = notification.object as? NSTableView,
              tableView.selectedRow >= 0,
              let agent = viewModel?.availableAgents[tableView.selectedRow] else { return }
        
        selectedAgentId = agent.id
        
        // 更新聊天标题
        if let titleLabel = window?.contentView?.subviews[1].subviews.first as? NSTextField {
            titleLabel.stringValue = "与 \(agent.name) 的聊天"
        }
        
        // 加载该 agent 的聊天记录
        loadChatHistory(for: agent.id)
    }
    
    private func loadChatHistory(for agentId: String) {
        chatTextView?.string = ""
        
        if let messages = chatHistories[agentId] {
            for message in messages {
                appendMessageToChatView(message)
            }
        }
    }
}
