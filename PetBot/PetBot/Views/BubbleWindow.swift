// BubbleWindow.swift
// 独立的气泡窗口 - 使用 AppKit 原生方法

import SwiftUI
import AppKit

@MainActor
class BubbleWindowController: NSObject {
    static let shared = BubbleWindowController()
    
    private var window: NSPanel?
    private var contentViewModel = BubbleContentViewModel()
    private var hideTimer: Timer?
    private var anchorWindowRef: NSWindow?
    
    var isVisible: Bool {
        window?.isVisible ?? false
    }
    
    func show(text: String, anchorWindow: NSWindow?) {
        // 保存锚定窗口引用，用于后续位置更新
        self.anchorWindowRef = anchorWindow
        
        // 创建窗口（如果不存在）
        if window == nil {
            createWindow()
        }
        
        // 更新内容
        contentViewModel.text = text
        contentViewModel.isEmpty = text.isEmpty
        
        // 每次显示都重新计算位置（解决宠物窗口移动后位置不对的问题）
        positionNearAnchor(anchorWindow)
        
        // 显示窗口
        window?.orderFront(nil)
        window?.alphaValue = 0.0
        
        // 使用动画显示
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            window?.animator().alphaValue = 1.0
        }
        
        // 重置自动隐藏定时器
        resetHideTimer()
        
        print("[PetBot] 气泡显示: \(text.prefix(30))...")
    }
    
    func hide() {
        guard let window = window, window.isVisible else { return }
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.1
            window.animator().alphaValue = 0.0
        } completionHandler: { [weak self] in
            Task { @MainActor in
                self?.window?.orderOut(nil)
            }
        }
        
        hideTimer?.invalidate()
        hideTimer = nil
    }
    
    func close() {
        window?.close()
        window = nil
        anchorWindowRef = nil
        hideTimer?.invalidate()
        hideTimer = nil
    }
    
    private func resetHideTimer() {
        hideTimer?.invalidate()
        
        let seconds = AppConfiguration.bubbleAutoHideSeconds
        guard seconds > 0 else { return }
        
        hideTimer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false) { [weak self] _ in
            Task { @MainActor in
                print("[PetBot] 气泡 \(Int(seconds)) 秒无新消息，自动隐藏")
                self?.hide()
            }
        }
    }
    
    private func createWindow() {
        // 使用 ObservableObject 来管理内容，确保 SwiftUI 正确响应
        let contentView = BubbleContentView(viewModel: contentViewModel)
        
        let hostingController = NSHostingController(rootView: contentView)
        
        // 创建窗口
        let window = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 280, height: 150),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        window.contentViewController = hostingController
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isMovableByWindowBackground = true
        
        // 设置窗口大小策略
        window.setContentSize(NSSize(width: 280, height: 150))
        
        self.window = window
    }
    
    private func positionNearAnchor(_ anchorWindow: NSWindow?) {
        guard let window = window else { return }
        
        let anchor = anchorWindow ?? anchorWindowRef
        
        guard let anchorFrame = anchor?.frame else {
            // 如果没有锚定窗口，居中显示在屏幕上
            if let screen = NSScreen.main {
                let screenFrame = screen.visibleFrame
                let x = screenFrame.midX - 140
                let y = screenFrame.midY - 75
                window.setFrameOrigin(NSPoint(x: x, y: y))
            }
            return
        }
        
        // 获取配置的偏移量
        let offsetX = AppConfiguration.bubbleOffsetX
        let offsetY = AppConfiguration.bubbleOffsetY
        
        // 气泡默认宽度
        let bubbleWidth: CGFloat = 280
        let bubbleHeight: CGFloat = 150
        
        // 计算位置：宠物窗口上方居中
        var x = anchorFrame.midX - (bubbleWidth / 2) + offsetX
        var y = anchorFrame.maxY + offsetY
        
        // 确保不超出屏幕边界
        if let screen = anchorWindow?.screen ?? NSScreen.main {
            let screenFrame = screen.visibleFrame
            
            // 右边界检查
            if x + bubbleWidth > screenFrame.maxX {
                x = screenFrame.maxX - bubbleWidth - 10
            }
            
            // 左边界检查
            if x < screenFrame.minX {
                x = screenFrame.minX + 10
            }
            
            // 上边界检查（如果上方空间不够，显示在下方）
            if y + bubbleHeight > screenFrame.maxY {
                y = anchorFrame.minY - bubbleHeight - offsetY
            }
        }
        
        window.setFrameOrigin(NSPoint(x: x, y: y))
        print("[PetBot] 气泡位置: (\(x), \(y)), 锚定窗口: (\(anchorFrame.origin.x), \(anchorFrame.origin.y))")
    }
}

// MARK: - Content View Model
@MainActor
class BubbleContentViewModel: ObservableObject {
    @Published var text: String = ""
    @Published var isEmpty: Bool = true
}

// MARK: - SwiftUI Content View
struct BubbleContentView: View {
    @ObservedObject var viewModel: BubbleContentViewModel
    @State private var contentHeight: CGFloat = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 关闭按钮
            HStack {
                Spacer()
                Button(action: { BubbleWindowController.shared.hide() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.gray.opacity(0.6))
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.top, 4)
                .padding(.trailing, 4)
            }
            
            // 内容区域
            ScrollView {
                Text(viewModel.isEmpty ? "(等待回复...)" : viewModel.text)
                    .font(.system(size: 14))
                    .foregroundColor(viewModel.isEmpty ? .gray : .black)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 240, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
            }
            .frame(maxHeight: 200)
        }
        .frame(width: 280)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.black.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

// MARK: - Preview
#Preview {
    let viewModel = BubbleContentViewModel()
    viewModel.text = "这是一个测试消息，用于预览气泡窗口的显示效果。"
    viewModel.isEmpty = false
    return BubbleContentView(viewModel: viewModel)
        .padding()
        .background(Color.gray.opacity(0.2))
}
