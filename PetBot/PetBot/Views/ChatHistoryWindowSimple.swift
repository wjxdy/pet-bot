// ChatHistoryWindow.swift
// 聊天历史窗口 - 简化版

import Cocoa

@MainActor
class ChatHistoryWindow: NSWindow {
    private var viewModel: AgentViewModel
    private var chatTextView: NSTextView?
    
    init(viewModel: AgentViewModel) {
        self.viewModel = viewModel
        
        super.init(
            contentRect: NSRect(x: 100, y: 100, width: 600, height: 400),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        self.title = "聊天历史"
        self.minSize = NSSize(width: 400, height: 300)
        
        setupUI()
        self.center()
    }
    
    private func setupUI() {
        // 简单文本视图显示聊天记录
        let scrollView = NSScrollView(frame: contentView!.bounds)
        scrollView.autoresizingMask = [.width, .height]
        scrollView.hasVerticalScroller = true
        
        let textView = NSTextView(frame: scrollView.bounds)
        textView.isEditable = false
        textView.font = NSFont.systemFont(ofSize: 13)
        textView.string = "与 \(viewModel.currentAgent.name) 的聊天记录\n\n"
        
        scrollView.documentView = textView
        contentView?.addSubview(scrollView)
        
        chatTextView = textView
    }
    
    func appendMessage(_ text: String, isUser: Bool) {
        let prefix = isUser ? "你" : viewModel.currentAgent.name
        chatTextView?.string += "[\(prefix)]: \(text)\n"
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
