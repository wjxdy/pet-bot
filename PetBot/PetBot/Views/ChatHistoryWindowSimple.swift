// ChatHistoryWindow.swift
// 聊天历史窗口 - 简化版

import Cocoa

@MainActor
class ChatHistoryWindow: NSWindow {
    private var viewModel: AgentViewModel
    private var chatTextView: NSTextView?
    private var tableView: NSTableView!
    private var splitView: NSSplitView!
    
    init(viewModel: AgentViewModel) {
        self.viewModel = viewModel
        
        super.init(
            contentRect: NSRect(x: 100, y: 100, width: 800, height: 500),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        self.title = "聊天历史"
        self.minSize = NSSize(width: 600, height: 400)
        
        setupUI()
        self.center()
    }
    
    private func setupUI() {
        // 创建分割视图
        splitView = NSSplitView()
        splitView.isVertical = true
        splitView.dividerStyle = .thin
        splitView.autoresizingMask = [.width, .height]
        splitView.frame = contentView!.bounds
        
        // MARK: - 左侧 Agent 列表
        let leftScrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: 200, height: contentView!.bounds.height))
        leftScrollView.hasVerticalScroller = true
        leftScrollView.autohidesScrollers = true
        
        tableView = NSTableView()
        tableView.headerView = nil
        tableView.selectionHighlightStyle = .regular
        tableView.allowsEmptySelection = false
        tableView.allowsMultipleSelection = false
        tableView.backgroundColor = NSColor.controlBackgroundColor
        
        // 创建列
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("AgentColumn"))
        column.title = "Agent"
        column.minWidth = 180
        column.maxWidth = 400
        tableView.addTableColumn(column)
        
        tableView.delegate = self
        tableView.dataSource = self
        
        // 设置当前选中的行
        updateTableViewSelection()
        
        leftScrollView.documentView = tableView
        splitView.addSubview(leftScrollView)
        
        // MARK: - 右侧聊天区域
        let rightScrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: contentView!.bounds.width - 200, height: contentView!.bounds.height))
        rightScrollView.hasVerticalScroller = true
        rightScrollView.autoresizingMask = [.width, .height]
        
        let textView = NSTextView(frame: rightScrollView.bounds)
        textView.isEditable = false
        textView.font = NSFont.systemFont(ofSize: 13)
        textView.string = "与 \(viewModel.currentAgent.name) 的聊天记录\n\n"
        textView.autoresizingMask = [.width, .height]
        
        rightScrollView.documentView = textView
        splitView.addSubview(rightScrollView)
        
        chatTextView = textView
        
        contentView?.addSubview(splitView)
        
        // 设置分割视图位置（左侧固定 200px）
        DispatchQueue.main.async { [weak self] in
            self?.splitView.setPosition(200, ofDividerAt: 0)
        }
    }
    
    private func updateTableViewSelection() {
        if let index = viewModel.availableAgents.firstIndex(where: { $0.id == viewModel.currentAgent.id }) {
            tableView?.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
        }
    }
    
    func appendMessage(_ text: String, isUser: Bool) {
        let prefix = isUser ? "你" : viewModel.currentAgent.name
        chatTextView?.string += "[\(prefix)]: \(text)\n"
    }
}

// MARK: - NSTableViewDataSource
extension ChatHistoryWindow: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return viewModel.availableAgents.count
    }
}

// MARK: - NSTableViewDelegate
extension ChatHistoryWindow: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cellIdentifier = NSUserInterfaceItemIdentifier("AgentCell")
        
        // 尝试复用单元格
        if let cell = tableView.makeView(withIdentifier: cellIdentifier, owner: self) as? NSTableCellView {
            configureCell(cell, at: row)
            return cell
        }
        
        // 创建新单元格
        let cell = NSTableCellView(frame: NSRect(x: 0, y: 0, width: 200, height: 28))
        cell.identifier = cellIdentifier
        
        // 图标
        let imageView = NSImageView(frame: NSRect(x: 8, y: 4, width: 20, height: 20))
        imageView.imageScaling = .scaleProportionallyUpOrDown
        cell.imageView = imageView
        
        // 文本
        let textField = NSTextField(frame: NSRect(x: 32, y: 4, width: 160, height: 20))
        textField.isEditable = false
        textField.isBordered = false
        textField.backgroundColor = .clear
        textField.font = NSFont.systemFont(ofSize: 13)
        textField.lineBreakMode = .byTruncatingTail
        cell.textField = textField
        
        cell.addSubview(imageView)
        cell.addSubview(textField)
        
        configureCell(cell, at: row)
        return cell
    }
    
    private func configureCell(_ cell: NSTableCellView, at row: Int) {
        guard row < viewModel.availableAgents.count else { return }
        
        let agent = viewModel.availableAgents[row]
        
        // 设置图标
        let iconName = agent.icon
        if !iconName.isEmpty {
            cell.imageView?.image = NSImage(systemSymbolName: iconName, accessibilityDescription: nil)
                ?? NSImage(systemSymbolName: "person.fill", accessibilityDescription: nil)
        } else {
            cell.imageView?.image = NSImage(systemSymbolName: "person.fill", accessibilityDescription: nil)
        }
        
        // 设置名称
        cell.textField?.stringValue = agent.name
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 28
    }
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return row < viewModel.availableAgents.count
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        let selectedRow = tableView.selectedRow
        guard selectedRow >= 0 && selectedRow < viewModel.availableAgents.count else { return }
        
        // 切换当前 Agent
        let selectedAgent = viewModel.availableAgents[selectedRow]
        viewModel.currentAgent = selectedAgent
        
        // 更新聊天标题和内容
        self.title = "与 \(selectedAgent.name) 的聊天"
        chatTextView?.string = "与 \(selectedAgent.name) 的聊天记录\n\n"
        
        // 可选：通知外部刷新聊天记录
        NotificationCenter.default.post(name: .init("AgentDidChange"), object: selectedAgent)
    }
}

@MainActor
class ChatHistoryManager {
    static var currentWindow: ChatHistoryWindow?
    
    static func show(viewModel: AgentViewModel) {
        if currentWindow == nil {
            currentWindow = ChatHistoryWindow(viewModel: viewModel)
        }
        currentWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    static func hide() {
        currentWindow?.orderOut(nil)
    }
}
