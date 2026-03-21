// InputWindow.swift
// 输入窗口控制器 - 豆包风格

import SwiftUI
import AppKit

// MARK: - SwiftUI Input View
struct ModernInputView: View {
    @State private var text = ""
    let onSend: (String) -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // 输入框
            TextField("给小米鼠发消息...", text: $text)
                .font(.system(size: 14))
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.15))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
                .onSubmit {
                    send()
                }
            
            // 发送按钮
            Button(action: send) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(text.isEmpty ? Color.white.opacity(0.2) : Color.white.opacity(0.4))
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private func send() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        onSend(trimmed)
        text = ""
    }
}

// MARK: - Window Controller
@MainActor
class InputWindowController: NSObject {
    static let shared = InputWindowController()
    
    private var window: NSPanel?
    private var hostingController: NSHostingController<ModernInputView>?
    private var onSendCallback: ((String) -> Void)?
    
    private let positionKey = "inputWindowPositionV2"
    
    var isVisible: Bool {
        window?.isVisible ?? false
    }
    
    func show(viewModel: AgentViewModel, onSend: @escaping (String) -> Void) {
        self.onSendCallback = onSend
        
        if window == nil {
            createWindow()
        }
        
        restorePosition()
        
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
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
        let inputView = ModernInputView(
            onSend: { [weak self] text in
                self?.onSendCallback?(text)
                self?.hide()
            },
            onDismiss: { [weak self] in
                self?.hide()
            }
        )
        
        let hostingController = NSHostingController(rootView: inputView)
        self.hostingController = hostingController
        
        // 使用 NSPanel 无边框样式，30%透明度背景
        let window = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 60),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        window.contentView = hostingController.view
        window.isOpaque = false
        window.backgroundColor = NSColor.black.withAlphaComponent(0.3) // 30%透明度
        window.hasShadow = true
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isMovableByWindowBackground = true
        
        // 圆角
        window.contentView?.wantsLayer = true
        window.contentView?.layer?.cornerRadius = 12
        window.contentView?.layer?.masksToBounds = true
        
        self.window = window
    }
    
    private func savePosition() {
        guard let frame = window?.frame else { return }
        UserDefaults.standard.set(["x": frame.origin.x, "y": frame.origin.y], forKey: positionKey)
    }
    
    private func restorePosition() {
        guard let window = window else { return }
        
        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let defaultX = screen.midX - 200
        let defaultY = screen.midY - 30
        
        if let pos = UserDefaults.standard.dictionary(forKey: positionKey) as? [String: Double],
           let x = pos["x"], let y = pos["y"] {
            window.setFrameOrigin(NSPoint(x: x, y: y))
        } else {
            window.setFrameOrigin(NSPoint(x: defaultX, y: defaultY))
        }
    }
}
