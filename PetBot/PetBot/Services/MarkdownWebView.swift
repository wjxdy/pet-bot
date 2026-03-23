// MarkdownWebView.swift
// 基于 WKWebView 的 Markdown 渲染器 - 使用统一的 MarkdownRenderer

import Cocoa
import WebKit

@MainActor
class MarkdownWebView: NSView {
    private var webView: WKWebView!
    
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
    
    /// 渲染 Markdown 文本
    func renderMarkdown(_ markdown: String) {
        let html = MarkdownRenderer.shared.renderHTML(markdown: markdown)
        webView.loadHTMLString(html, baseURL: nil)
    }
    
    /// 追加 Markdown 文本
    func appendMarkdown(_ markdown: String) {
        let script = MarkdownRenderer.shared.appendScript(text: markdown)
        webView.evaluateJavaScript(script, completionHandler: nil)
    }
    
    /// 追加 HTML 内容（直接追加，不解析 Markdown）
    func appendHTML(_ html: String) {
        guard let data = html.data(using: .utf8) else { return }
        let base64 = data.base64EncodedString()
        
        let script = """
        (function() {
            try {
                var htmlContent = decodeURIComponent(escape(atob('\(base64)')));
                var content = document.getElementById('content');
                if (content) {
                    content.insertAdjacentHTML('beforeend', htmlContent);
                    window.scrollTo(0, document.body.scrollHeight);
                }
            } catch(e) {
                console.error('Append HTML failed:', e);
            }
        })();
        """
        
        webView.evaluateJavaScript(script, completionHandler: nil)
    }
    
    /// 滚动到底部
    func scrollToBottom() {
        webView.evaluateJavaScript("window.scrollTo(0, document.body.scrollHeight);", completionHandler: nil)
    }
}
