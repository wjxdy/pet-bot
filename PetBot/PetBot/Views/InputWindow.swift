// InputWindow.swift
// 输入窗口 - 确保可输入

import SwiftUI
import AppKit

struct InputContainerView: View {
    let onSend: (String) -> Void
    
    var body: some View {
        InputFieldRepresentable(onSend: onSend)
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: 5)
            .frame(width: 400, height: 70)
    }
}

// 使用 NSRepresentable 确保原生输入
struct InputFieldRepresentable: NSViewRepresentable {
    let onSend: (String) -> Void
    
    func makeNSView(context: Context) -> NSView {
        let container = NSView()
        
        // 创建 NSTextField
        let textField = NSTextField()
        textField.placeholderString = "输入消息..."
        textField.font = NSFont.systemFont(ofSize: 14)
        textField.isEditable = true
        textField.isSelectable = true
        textField.focusRingType = .default
        textField.bezelStyle = .roundedBezel
        textField.target = context.coordinator
        textField.action = #selector(Coordinator.submit)
        
        // 创建发送按钮
        let button = NSButton(title: "发送", target: context.coordinator, action: #selector(Coordinator.submit))
        button.bezelStyle = .rounded
        button.keyEquivalent = "\r" // 回车键
        
        // 布局
        textField.translatesAutoresizingMaskIntoConstraints = false
        button.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(textField)
        container.addSubview(button)
        
        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            textField.topAnchor.constraint(equalTo: container.topAnchor),
            textField.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            textField.trailingAnchor.constraint(equalTo: button.leadingAnchor, constant: -8),
            
            button.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            button.topAnchor.constraint(equalTo: container.topAnchor),
            button.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            button.widthAnchor.constraint(equalToConstant: 60)
        ])
        
        context.coordinator.textField = textField
        context.coordinator.onSend = onSend
        
        // 延迟设置焦点
        DispatchQueue.main.async {
            textField.window?.makeFirstResponder(textField)
        }
        
        return container
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject {
        weak var textField: NSTextField?
        var onSend: ((String) -> Void)?
        
        @objc func submit() {
            guard let text = textField?.stringValue.trimmingCharacters(in: .whitespaces),
                  !text.isEmpty else { return }
            onSend?(text)
            textField?.stringValue = ""
        }
    }
}

@MainActor
class InputWindowController: NSObject {
    static let shared = InputWindowController()
    
    private var window: NSPanel?
    private var onSendCallback: ((String) -> Void)?
    
    var isVisible: Bool {
        window?.isVisible ?? false
    }
    
    func show(viewModel: AgentViewModel, onSend: @escaping (String) -> Void) {
        self.onSendCallback = onSend
        
        if window == nil {
            createWindow()
        }
        
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }
    
    func hide() {
        window?.orderOut(nil)
    }
    
    func close() {
        window?.close()
        window = nil
    }
    
    private func createWindow() {
        let contentView = InputContainerView { [weak self] text in
            self?.onSendCallback?(text)
            self?.hide()
        }
        
        let hostingController = NSHostingController(rootView: contentView)
        
        let window = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 70),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        window.contentView = hostingController.view
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isMovableByWindowBackground = true
        
        window.center()
        
        self.window = window
    }
}
