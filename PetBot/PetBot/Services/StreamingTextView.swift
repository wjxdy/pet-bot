// StreamingTextView.swift
// 流式文本显示 - 打字机效果

import Cocoa
import WebKit

@MainActor
class StreamingBubbleView: NSView {
    private var webView: WKWebView!
    private var currentText: String = ""
    private var isStreaming: Bool = false
    
    var onContentHeightChange: ((CGFloat) -> Void)?
    
    override init(frame: NSRect) {
        super.init(frame: frame)
        setupWebView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupWebView()
    }
    
    private func setupWebView() {
        let config = WKWebViewConfiguration()
        config.preferences.javaScriptEnabled = true
        
        webView = WKWebView(frame: bounds, configuration: config)
        webView.autoresizingMask = [.width, .height]
        
        addSubview(webView)
    }
    
    /// 开始流式输出
    func startStreaming() {
        currentText = ""
        isStreaming = true
        let html = MarkdownRenderer.shared.renderHTMLWithCursor(markdown: "")
        webView.loadHTMLString(html, baseURL: nil)
    }
    
    /// 追加文本（流式）- 使用 JavaScript 注入避免闪烁
    func appendText(_ text: String) {
        guard isStreaming else { return }
        
        currentText += text
        
        // 使用 JavaScript 追加内容，避免重新加载整个页面
        let script = MarkdownRenderer.shared.appendScript(text: text)
        webView.evaluateJavaScript(script) { [weak self] _, _ in
            self?.checkContentHeight()
        }
    }
    
    /// 结束流式输出
    func endStreaming() {
        isStreaming = false
        // 移除光标
        webView.evaluateJavaScript("""
            var cursor = document.querySelector('.cursor');
            if (cursor) cursor.remove();
        """) { _, _ in }
    }
    
    /// 设置最终文本（非流式）
    func setText(_ text: String) {
        currentText = text
        isStreaming = false
        let html = MarkdownRenderer.shared.renderHTML(markdown: text)
        webView.loadHTMLString(html, baseURL: nil)
        checkContentHeight()
    }
    
    /// 清空内容
    func clear() {
        currentText = ""
        isStreaming = false
        let html = MarkdownRenderer.shared.renderHTMLWithCursor(markdown: "")
        webView.loadHTMLString(html, baseURL: nil)
    }
    
    private func checkContentHeight() {
        webView.evaluateJavaScript("document.body.scrollHeight") { [weak self] result, _ in
            if let height = result as? CGFloat {
                DispatchQueue.main.async {
                    self?.onContentHeightChange?(min(height + 24, 300))
                }
            }
        }
    }
    
    /// 获取内容高度
    func getContentHeight(completion: @escaping (CGFloat) -> Void) {
        webView.evaluateJavaScript("document.body.scrollHeight") { result, _ in
            if let height = result as? CGFloat {
                completion(min(height + 24, 300))
            } else {
                completion(80)
            }
        }
    }
}
