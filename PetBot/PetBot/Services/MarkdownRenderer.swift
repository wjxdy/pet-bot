// MarkdownRenderer.swift
// 统一的 Markdown 渲染器 - 气泡框和历史对话框共享

import Cocoa
import WebKit

@MainActor
class MarkdownRenderer {
    static let shared = MarkdownRenderer()
    
    // 完整的 CSS 样式（RPG 羊皮纸风格）
    private let cssStyles = """
    <style>
        /* 基础样式 */
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'PingFang SC', 'Microsoft YaHei', monospace;
            font-size: 14px;
            line-height: 1.6;
            color: #2c1810;
            background: transparent;
            overflow-wrap: break-word;
            word-wrap: break-word;
        }
        
        /* 标题 */
        h1, h2, h3, h4, h5, h6 {
            margin: 12px 0 8px;
            font-weight: 600;
            color: #4a3728;
            border-bottom: 2px solid #d4c4a8;
            padding-bottom: 4px;
        }
        h1 { font-size: 1.5em; }
        h2 { font-size: 1.3em; }
        h3 { font-size: 1.15em; }
        h4, h5, h6 { font-size: 1em; }
        
        /* 段落 */
        p {
            margin-bottom: 8px;
        }
        p:last-child {
            margin-bottom: 0;
        }
        
        /* 行内代码 */
        code {
            background: rgba(139, 90, 43, 0.12);
            padding: 2px 6px;
            border-radius: 4px;
            font-family: 'SF Mono', Monaco, 'Courier New', monospace;
            font-size: 0.9em;
            color: #8b4513;
        }
        
        /* 代码块 */
        pre {
            background: #f8f4ed;
            padding: 12px;
            border-radius: 8px;
            overflow-x: auto;
            margin: 10px 0;
            border: 1px solid #e8dfd0;
        }
        pre code {
            background: transparent;
            padding: 0;
            color: #333;
            font-size: 0.85em;
            line-height: 1.5;
        }
        
        /* 语法高亮 */
        .hljs {
            background: transparent;
        }
        .hljs-keyword { color: #d73a49; }
        .hljs-string { color: #032f62; }
        .hljs-number { color: #005cc5; }
        .hljs-function { color: #6f42c1; }
        .hljs-comment { color: #6a737d; font-style: italic; }
        .hljs-operator { color: #d73a49; }
        
        /* 表格 */
        table {
            border-collapse: collapse;
            margin: 12px 0;
            width: 100%;
            font-size: 0.95em;
        }
        th, td {
            border: 1px solid #d4c4a8;
            padding: 8px 12px;
            text-align: left;
        }
        th {
            background: #f5f0e6;
            font-weight: 600;
            color: #4a3728;
        }
        tr:nth-child(even) {
            background: rgba(245, 240, 230, 0.5);
        }
        tr:hover {
            background: rgba(212, 196, 168, 0.2);
        }
        
        /* 任务列表 */
        .task-list-item {
            list-style-type: none;
            margin-left: -20px;
        }
        .task-list-item input[type="checkbox"] {
            margin-right: 8px;
            accent-color: #8b4513;
            cursor: default;
        }
        
        /* 引用块 */
        blockquote {
            border-left: 4px solid #c4a574;
            padding: 8px 16px;
            margin: 10px 0;
            color: #666;
            font-style: italic;
            background: rgba(196, 165, 116, 0.1);
            border-radius: 0 4px 4px 0;
        }
        blockquote p:last-child {
            margin-bottom: 0;
        }
        
        /* 分隔线 */
        hr {
            border: none;
            border-top: 2px dashed #d4c4a8;
            margin: 16px 0;
        }
        
        /* 链接 */
        a {
            color: #8b4513;
            text-decoration: none;
            border-bottom: 1px dotted #8b4513;
            transition: background 0.2s;
        }
        a:hover {
            background: rgba(139, 69, 19, 0.1);
        }
        
        /* 列表 */
        ul, ol {
            margin: 8px 0 8px 24px;
        }
        li {
            margin: 4px 0;
        }
        ul ul, ol ol, ul ol, ol ul {
            margin: 4px 0 4px 20px;
        }
        
        /* 图片 */
        img {
            max-width: 100%;
            border-radius: 4px;
            margin: 8px 0;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        
        /* 删除线 */
        del {
            color: #999;
            text-decoration: line-through;
        }
        
        /* 粗体和斜体 */
        strong {
            font-weight: 600;
            color: #3d2b1f;
        }
        em {
            font-style: italic;
        }
        
        /* 打字机光标 */
        .cursor {
            display: inline-block;
            width: 2px;
            height: 1.2em;
            background-color: #8b4513;
            animation: blink 1s infinite;
            vertical-align: text-bottom;
            margin-left: 2px;
        }
        @keyframes blink {
            0%, 50% { opacity: 1; }
            51%, 100% { opacity: 0; }
        }
    </style>
    """
    
    // CDN 资源
    private let markedJS = "https://cdn.jsdelivr.net/npm/marked/marked.min.js"
    private let highlightJS = "https://cdn.jsdelivr.net/npm/highlight.js@11/lib/core.min.js"
    private let highlightLanguages = [
        ("javascript", "https://cdn.jsdelivr.net/npm/highlight.js@11/lib/languages/javascript.min.js"),
        ("swift", "https://cdn.jsdelivr.net/npm/highlight.js@11/lib/languages/swift.min.js"),
        ("python", "https://cdn.jsdelivr.net/npm/highlight.js@11/lib/languages/python.min.js"),
        ("bash", "https://cdn.jsdelivr.net/npm/highlight.js@11/lib/languages/bash.min.js"),
        ("json", "https://cdn.jsdelivr.net/npm/highlight.js@11/lib/languages/json.min.js"),
        ("yaml", "https://cdn.jsdelivr.net/npm/highlight.js@11/lib/languages/yaml.min.js"),
        ("sql", "https://cdn.jsdelivr.net/npm/highlight.js@11/lib/languages/sql.min.js")
    ]
    
    /// 渲染 Markdown 为完整 HTML
    func renderHTML(markdown: String) -> String {
        guard let data = markdown.data(using: .utf8) else { return "" }
        let base64 = data.base64EncodedString()
        
        let langScripts = highlightLanguages.map { _, url in
            "<script src=\"\(url)\"></script>"
        }.joined(separator: "\n")
        
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            \(cssStyles)
            <script src="\(markedJS)"></script>
            <script src="\(highlightJS)"></script>
            \(langScripts)
        </head>
        <body>
            <div id="content"></div>
            <script>
                // 配置 marked
                marked.setOptions({
                    gfm: true,
                    breaks: true,
                    headerIds: false,
                    mangle: false,
                    highlight: function(code, lang) {
                        if (lang && hljs.getLanguage(lang)) {
                            try {
                                return hljs.highlight(code, { language: lang }).value;
                            } catch (e) {}
                        }
                        try {
                            return hljs.highlightAuto(code).value;
                        } catch (e) {
                            return code;
                        }
                    }
                });
                
                // 渲染内容
                try {
                    // 使用 Uint8Array 正确解码 UTF-8
                    var binary = atob('\(base64)');
                    var bytes = new Uint8Array(binary.length);
                    for (var i = 0; i < binary.length; i++) {
                        bytes[i] = binary.charCodeAt(i);
                    }
                    var decoder = new TextDecoder('utf-8');
                    var markdownText = decoder.decode(bytes);
                    
                    var parsedHtml = marked.parse(markdownText);
                    document.getElementById('content').innerHTML = parsedHtml;
                } catch(e) {
                    // 降级处理
                    document.getElementById('content').innerText = atob('\(base64)');
                }
            </script>
        </body>
        </html>
        """
    }
    
    /// 渲染带光标的 Markdown（用于流式输出）
    func renderHTMLWithCursor(markdown: String) -> String {
        guard let data = markdown.data(using: .utf8) else { return "" }
        let base64 = data.base64EncodedString()
        
        let langScripts = highlightLanguages.map { _, url in
            "<script src=\"\(url)\"></script>"
        }.joined(separator: "\n")
        
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            \(cssStyles)
            <script src="\(markedJS)"></script>
            <script src="\(highlightJS)"></script>
            \(langScripts)
        </head>
        <body>
            <div id="content"><span class="cursor"></span></div>
            <script>
                marked.setOptions({
                    gfm: true,
                    breaks: true,
                    headerIds: false,
                    mangle: false,
                    highlight: function(code, lang) {
                        if (lang && hljs.getLanguage(lang)) {
                            try {
                                return hljs.highlight(code, { language: lang }).value;
                            } catch (e) {}
                        }
                        try {
                            return hljs.highlightAuto(code).value;
                        } catch (e) {
                            return code;
                        }
                    }
                });
                
                try {
                    // 使用 Uint8Array 正确解码 UTF-8
                    var binary = atob('\(base64)');
                    var bytes = new Uint8Array(binary.length);
                    for (var i = 0; i < binary.length; i++) {
                        bytes[i] = binary.charCodeAt(i);
                    }
                    var decoder = new TextDecoder('utf-8');
                    var markdownText = decoder.decode(bytes);
                    
                    var parsedHtml = marked.parse(markdownText);
                    document.getElementById('content').innerHTML = parsedHtml;
                    
                    // 添加光标
                    var cursor = document.createElement('span');
                    cursor.className = 'cursor';
                    document.getElementById('content').appendChild(cursor);
                } catch(e) {
                    var text = atob('\(base64)');
                    var cursor = document.createElement('span');
                    cursor.className = 'cursor';
                    var content = document.getElementById('content');
                    content.innerText = text;
                    content.appendChild(cursor);
                }
            </script>
        </body>
        </html>
        """
    }
    
    /// 追加 HTML 到现有内容（用于流式追加）
    func appendScript(text: String) -> String {
        guard let data = text.data(using: .utf8) else { return "" }
        let base64 = data.base64EncodedString()
        
        return """
        (function() {
            var content = document.getElementById('content');
            var cursor = content.querySelector('.cursor');
            try {
                // 使用 Uint8Array 正确解码 UTF-8
                var binary = atob('\(base64)');
                var bytes = new Uint8Array(binary.length);
                for (var i = 0; i < binary.length; i++) {
                    bytes[i] = binary.charCodeAt(i);
                }
                var decoder = new TextDecoder('utf-8');
                var newText = decoder.decode(bytes);
                
                var tempDiv = document.createElement('div');
                tempDiv.innerHTML = marked.parse(newText);
                
                // 移除光标，添加新内容，再添加光标
                if (cursor) cursor.remove();
                while (tempDiv.firstChild) {
                    content.appendChild(tempDiv.firstChild);
                }
                var newCursor = document.createElement('span');
                newCursor.className = 'cursor';
                content.appendChild(newCursor);
            } catch(e) {
                if (cursor) cursor.remove();
                var decoder = new TextDecoder('utf-8');
                var binary = atob('\(base64)');
                var bytes = new Uint8Array(binary.length);
                for (var i = 0; i < binary.length; i++) {
                    bytes[i] = binary.charCodeAt(i);
                }
                content.appendChild(document.createTextNode(decoder.decode(bytes)));
                var newCursor = document.createElement('span');
                newCursor.className = 'cursor';
                content.appendChild(newCursor);
            }
        })();
        """
    }
}
