// InputWindow.swift
// 输入框窗口控制器 - 使用 SwiftUI TextField 嵌入 AppKit

import SwiftUI
import AppKit

// SwiftUI 输入视图
struct InputView: View {
    @State private var text = ""
    var onSend: (String) -> Void
    var onDismiss: () -> Void
    var agentName: String
    
    var body: some View {
        HStack(spacing: 12) {
            // 输入框
            TextField("给 \(agentName) 发送消息...", text: $text)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.6))
                )
                .onSubmit {
                    send()
                }
            
            // 发送按钮
            Button(action: send) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.5))
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.40))
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 8)
        )
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
    
    private let positionKey = "inputWindowPositionV7"
    
    var isVisible: Bool {
        return window?.isVisible ?? false
    }
    
    func show(agentManager: AgentManager, onSend: @escaping (String) -> Void) {
        self.agentManager = agentManager
        self.onSendCallback = onSend
        
        if window == nil {
            createWindow()
        }
        
        // 更新 hosting controller 中的 agentName
        updateHostingController()
        
        restorePosition()
        
        guard let window = window else { return }
        
        // 激活应用并显示窗口
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
            onDismiss: { [weak self] in
                self?.hide()
            },
            agentName: agentManager?.currentAgent.name ?? "Agent"
        )
        
        // 创建 hosting controller
        let hostingController = NSHostingController(rootView: inputView)
        self.hostingController = hostingController
        
        // 创建窗口
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 80),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isMovableByWindowBackground = true
        window.contentViewController = hostingController
        
        self.window = window
    }
    
    private func updateHostingController() {
        guard let onSend = onSendCallback else { return }
        
        let inputView = InputView(
            onSend: { [weak self] text in
                self?.onSendCallback?(text)
                self?.hide()
            },
            onDismiss: { [weak self] in
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
        let defaultX = screen.midX - 200
        let defaultY = screen.midY - 40
        
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
