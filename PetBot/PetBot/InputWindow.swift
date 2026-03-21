// InputWindow.swift
// 简化版 - 使用标准窗口样式测试输入

import SwiftUI
import AppKit

// SwiftUI 输入视图
struct InputView: View {
    @State private var text = ""
    var onSend: (String) -> Void
    var agentName: String
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text(agentName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.1))
            
            Divider()
            
            // 输入区域
            HStack(spacing: 8) {
                TextField("输入消息...", text: $text)
                    .font(.system(size: 14))
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(6)
                    .onSubmit {
                        send()
                    }
                
                Button(action: send) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 14, weight: .bold))
                }
                .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(12)
        }
        .frame(width: 300)
    }
    
    private func send() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        onSend(trimmed)
        text = ""
    }
}

@MainActor
class InputWindowController: NSObject {
    static let shared = InputWindowController()
    
    private var window: NSWindow?
    private var hostingController: NSHostingController<InputView>?
    private var agentManager: AgentManager?
    private var onSendCallback: ((String) -> Void)?
    
    private let positionKey = "inputWindowPositionV8"
    
    var isVisible: Bool {
        return window?.isVisible ?? false
    }
    
    func show(agentManager: AgentManager, onSend: @escaping (String) -> Void) {
        self.agentManager = agentManager
        self.onSendCallback = onSend
        
        if window == nil {
            createWindow()
        } else {
            updateHostingController()
        }
        
        restorePosition()
        
        guard let window = window else { return }
        
        // 激活并显示
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }
    
    func hide() {
        savePosition()
        window?.orderOut(nil)
    }
    
    func close() {
        savePosition()
        window?.close()
        window = nil
        hostingController = nil
    }
    
    private func createWindow() {
        // 创建 SwiftUI 视图
        let inputView = InputView(
            onSend: { [weak self] text in
                self?.onSendCallback?(text)
                self?.hide()
            },
            agentName: agentManager?.currentAgent.name ?? "Agent"
        )
        
        // 创建 hosting controller
        let hostingController = NSHostingController(rootView: inputView)
        self.hostingController = hostingController
        
        // 创建窗口 - 使用标准窗口样式（带标题栏）
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 100),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "PetBot 输入"
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces]
        window.contentViewController = hostingController
        window.isReleasedWhenClosed = false
        
        self.window = window
    }
    
    private func updateHostingController() {
        let inputView = InputView(
            onSend: { [weak self] text in
                self?.onSendCallback?(text)
                self?.hide()
            },
            agentName: agentManager?.currentAgent.name ?? "Agent"
        )
        hostingController?.rootView = inputView
    }
    
    private func savePosition() {
        guard let win = window else { return }
        let frame = win.frame
        UserDefaults.standard.set(["x": frame.origin.x, "y": frame.origin.y], forKey: positionKey)
    }
    
    private func restorePosition() {
        guard let win = window else { return }
        
        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let defaultX = screen.midX - 150
        let defaultY = screen.midY - 50
        
        if let pos = UserDefaults.standard.dictionary(forKey: positionKey) as? [String: Double],
           let x = pos["x"], let y = pos["y"] {
            win.setFrameOrigin(NSPoint(x: x, y: y))
        } else {
            win.setFrameOrigin(NSPoint(x: defaultX, y: defaultY))
        }
    }
}

// Pet 窗口控制器
@MainActor
class PetWindowController: NSObject {
    static let shared = PetWindowController()
    weak var petWindow: NSWindow?
}
