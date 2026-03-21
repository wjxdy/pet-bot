// InputWindow.swift
// 输入窗口控制器

import SwiftUI
import AppKit

// MARK: - SwiftUI Input View
struct ModernInputView: View {
    @State private var text = ""
    let viewModel: AgentViewModel
    let onSend: (String) -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text(viewModel.currentAgent.name)
                    .font(.system(size: 12, weight: .medium))
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12))
                }
                .buttonStyle(PlainButtonStyle())
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
        .frame(width: AppConfiguration.inputWindowSize.width)
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
    
    private var window: NSWindow?
    private var hostingController: NSHostingController<ModernInputView>?
    private weak var viewModel: AgentViewModel?
    private var onSendCallback: ((String) -> Void)?
    
    private let positionKey = "inputWindowPosition"
    
    var isVisible: Bool {
        window?.isVisible ?? false
    }
    
    func show(viewModel: AgentViewModel, onSend: @escaping (String) -> Void) {
        self.viewModel = viewModel
        self.onSendCallback = onSend
        
        if window == nil {
            createWindow()
        } else {
            updateContent()
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
        guard let viewModel = viewModel, let onSend = onSendCallback else { return }
        
        let inputView = ModernInputView(
            viewModel: viewModel,
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
        
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: AppConfiguration.inputWindowSize),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "PetBot"
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces]
        window.contentViewController = hostingController
        window.isReleasedWhenClosed = false
        
        self.window = window
    }
    
    private func updateContent() {
        guard let viewModel = viewModel, let onSend = onSendCallback else { return }
        
        let inputView = ModernInputView(
            viewModel: viewModel,
            onSend: { [weak self] text in
                self?.onSendCallback?(text)
                self?.hide()
            },
            onDismiss: { [weak self] in
                self?.hide()
            }
        )
        
        hostingController?.rootView = inputView
    }
    
    private func savePosition() {
        guard let frame = window?.frame else { return }
        UserDefaults.standard.set(["x": frame.origin.x, "y": frame.origin.y], forKey: positionKey)
    }
    
    private func restorePosition() {
        guard let window = window else { return }
        
        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let defaultX = screen.midX - AppConfiguration.inputWindowSize.width / 2
        let defaultY = screen.midY - AppConfiguration.inputWindowSize.height / 2
        
        if let pos = UserDefaults.standard.dictionary(forKey: positionKey) as? [String: Double],
           let x = pos["x"], let y = pos["y"] {
            window.setFrameOrigin(NSPoint(x: x, y: y))
        } else {
            window.setFrameOrigin(NSPoint(x: defaultX, y: defaultY))
        }
    }
}
