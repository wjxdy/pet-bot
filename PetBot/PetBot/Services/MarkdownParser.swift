// MarkdownParser.swift
// Markdown 解析器 - 将 Markdown 转换为 NSAttributedString

import Cocoa

@MainActor
class MarkdownParser {
    static let shared = MarkdownParser()
    
    private init() {}
    
    /// 将 Markdown 文本转换为 NSAttributedString
    func parse(_ markdown: String, baseFont: NSFont = NSFont.systemFont(ofSize: 13)) -> NSAttributedString {
        let attributedString = NSMutableAttributedString()
        
        // 按行分割处理
        let lines = markdown.components(separatedBy: .newlines)
        
        for (index, line) in lines.enumerated() {
            let lineAttributedString = parseLine(line, baseFont: baseFont)
            attributedString.append(lineAttributedString)
            
            // 添加换行（除了最后一行）
            if index < lines.count - 1 {
                attributedString.append(NSAttributedString(string: "\n"))
            }
        }
        
        return attributedString
    }
    
    /// 解析单行 Markdown
    private func parseLine(_ line: String, baseFont: NSFont) -> NSAttributedString {
        var result = NSMutableAttributedString(string: line)
        
        // 应用基础字体
        result.addAttribute(.font, value: baseFont, range: NSRange(location: 0, length: result.length))
        
        // 解析各种 Markdown 元素
        result = parseHeaders(result, baseFont: baseFont)
        result = parseBold(result, baseFont: baseFont)
        result = parseItalic(result, baseFont: baseFont)
        result = parseCode(result, baseFont: baseFont)
        result = parseInlineCode(result, baseFont: baseFont)
        result = parseLinks(result)
        result = parseStrikethrough(result)
        
        return result
    }
    
    // MARK: - 标题解析 (# ## ###)
    private func parseHeaders(_ attributedString: NSMutableAttributedString, baseFont: NSFont) -> NSMutableAttributedString {
        let patterns = [
            ("^#{6}\\s+", NSFont.systemFont(ofSize: baseFont.pointSize + 1)),
            ("^#{5}\\s+", NSFont.systemFont(ofSize: baseFont.pointSize + 2)),
            ("^#{4}\\s+", NSFont.systemFont(ofSize: baseFont.pointSize + 3)),
            ("^#{3}\\s+", NSFont.systemFont(ofSize: baseFont.pointSize + 4)),
            ("^#{2}\\s+", NSFont.systemFont(ofSize: baseFont.pointSize + 5)),
            ("^#\\s+", NSFont.systemFont(ofSize: baseFont.pointSize + 6))
        ]
        
        for (pattern, font) in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let range = NSRange(location: 0, length: attributedString.length)
                if let match = regex.firstMatch(in: attributedString.string, options: [], range: range) {
                    // 删除 Markdown 标记
                    attributedString.deleteCharacters(in: match.range)
                    // 应用标题字体
                    attributedString.addAttribute(.font, value: font, range: NSRange(location: 0, length: attributedString.length))
                    attributedString.addAttribute(.foregroundColor, value: NSColor.textColor, range: NSRange(location: 0, length: attributedString.length))
                    break
                }
            }
        }
        
        return attributedString
    }
    
    // MARK: - 粗体解析 (**text** 或 __text__)
    private func parseBold(_ attributedString: NSMutableAttributedString, baseFont: NSFont) -> NSMutableAttributedString {
        let patterns = [
            "\\*\\*(.+?)\\*\\*",  // **text**
            "__(.+?)__"            // __text__
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let range = NSRange(location: 0, length: attributedString.length)
                let matches = regex.matches(in: attributedString.string, options: [], range: range)
                
                // 从后向前处理，避免位置变化
                for match in matches.reversed() {
                    let contentRange = match.range(at: 1)
                    let fullRange = match.range
                    
                    // 获取内容
                    let content = attributedString.attributedSubstring(from: contentRange)
                    
                    // 创建粗体属性
                    let boldFont = NSFont.boldSystemFont(ofSize: baseFont.pointSize)
                    let boldContent = NSMutableAttributedString(attributedString: content)
                    boldContent.addAttribute(.font, value: boldFont, range: NSRange(location: 0, length: boldContent.length))
                    
                    // 替换原文
                    attributedString.replaceCharacters(in: fullRange, with: boldContent)
                }
            }
        }
        
        return attributedString
    }
    
    // MARK: - 斜体解析 (*text* 或 _text_)
    private func parseItalic(_ attributedString: NSMutableAttributedString, baseFont: NSFont) -> NSMutableAttributedString {
        // 注意：需要排除已经是粗体的 **text**
        let patterns = [
            "\\*(.+?)\\*",   // *text*
            "_(.+?)_"        // _text_
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let range = NSRange(location: 0, length: attributedString.length)
                let matches = regex.matches(in: attributedString.string, options: [], range: range)
                
                for match in matches.reversed() {
                    let contentRange = match.range(at: 1)
                    let fullRange = match.range
                    
                    // 跳过已经是粗体的内容（包含 **）
                    let matchedText = attributedString.string.substring(with: Range(fullRange, in: attributedString.string) ?? attributedString.string.startIndex..<attributedString.string.endIndex)
                    if matchedText.contains("**") || matchedText.contains("__") {
                        continue
                    }
                    
                    // 获取内容
                    let content = attributedString.attributedSubstring(from: contentRange)
                    
                    // 创建斜体属性
                    let italicFont = NSFontManager.shared.convert(baseFont, toHaveTrait: .italicFontMask)
                    let italicContent = NSMutableAttributedString(attributedString: content)
                    italicContent.addAttribute(.font, value: italicFont, range: NSRange(location: 0, length: italicContent.length))
                    
                    // 替换原文
                    attributedString.replaceCharacters(in: fullRange, with: italicContent)
                }
            }
        }
        
        return attributedString
    }
    
    // MARK: - 代码块解析 (```code```)
    private func parseCode(_ attributedString: NSMutableAttributedString, baseFont: NSFont) -> NSMutableAttributedString {
        let pattern = "```(?:\\w*)?\\n?([^`]+)```"
        
        if let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) {
            let range = NSRange(location: 0, length: attributedString.length)
            let matches = regex.matches(in: attributedString.string, options: [], range: range)
            
            for match in matches.reversed() {
                let contentRange = match.range(at: 1)
                let fullRange = match.range
                
                // 获取内容
                let content = (attributedString.string as NSString).substring(with: contentRange)
                
                // 创建代码块样式
                let codeFont = NSFont.monospacedSystemFont(ofSize: baseFont.pointSize - 1, weight: .regular)
                let codeAttributes: [NSAttributedString.Key: Any] = [
                    .font: codeFont,
                    .foregroundColor: NSColor.textColor,
                    .backgroundColor: NSColor.controlBackgroundColor
                ]
                
                let codeString = NSMutableAttributedString(string: content, attributes: codeAttributes)
                
                // 替换原文
                attributedString.replaceCharacters(in: fullRange, with: codeString)
            }
        }
        
        return attributedString
    }
    
    // MARK: - 行内代码解析 (`code`)
    private func parseInlineCode(_ attributedString: NSMutableAttributedString, baseFont: NSFont) -> NSMutableAttributedString {
        let pattern = "`([^`]+)`"
        
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let range = NSRange(location: 0, length: attributedString.length)
            let matches = regex.matches(in: attributedString.string, options: [], range: range)
            
            for match in matches.reversed() {
                let contentRange = match.range(at: 1)
                let fullRange = match.range
                
                // 获取内容
                let content = (attributedString.string as NSString).substring(with: contentRange)
                
                // 创建行内代码样式
                let codeFont = NSFont.monospacedSystemFont(ofSize: baseFont.pointSize - 1, weight: .regular)
                let codeAttributes: [NSAttributedString.Key: Any] = [
                    .font: codeFont,
                    .foregroundColor: NSColor.systemPink,
                    .backgroundColor: NSColor.controlBackgroundColor
                ]
                
                let codeString = NSAttributedString(string: content, attributes: codeAttributes)
                
                // 替换原文
                attributedString.replaceCharacters(in: fullRange, with: codeString)
            }
        }
        
        return attributedString
    }
    
    // MARK: - 链接解析 ([text](url))
    private func parseLinks(_ attributedString: NSMutableAttributedString) -> NSMutableAttributedString {
        let pattern = "\\[([^\\]]+)\\]\\(([^\\)]+)\\)"
        
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let range = NSRange(location: 0, length: attributedString.length)
            let matches = regex.matches(in: attributedString.string, options: [], range: range)
            
            for match in matches.reversed() {
                let textRange = match.range(at: 1)
                let urlRange = match.range(at: 2)
                let fullRange = match.range
                
                // 获取文本和 URL
                let text = (attributedString.string as NSString).substring(with: textRange)
                let url = (attributedString.string as NSString).substring(with: urlRange)
                
                // 创建链接样式
                let linkAttributes: [NSAttributedString.Key: Any] = [
                    .foregroundColor: NSColor.linkColor,
                    .underlineStyle: NSUnderlineStyle.single.rawValue,
                    .link: URL(string: url) ?? ""
                ]
                
                let linkString = NSAttributedString(string: text, attributes: linkAttributes)
                
                // 替换原文
                attributedString.replaceCharacters(in: fullRange, with: linkString)
            }
        }
        
        return attributedString
    }
    
    // MARK: - 删除线解析 (~~text~~)
    private func parseStrikethrough(_ attributedString: NSMutableAttributedString) -> NSMutableAttributedString {
        let pattern = "~~(.+?)~~"
        
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let range = NSRange(location: 0, length: attributedString.length)
            let matches = regex.matches(in: attributedString.string, options: [], range: range)
            
            for match in matches.reversed() {
                let contentRange = match.range(at: 1)
                let fullRange = match.range
                
                // 获取内容
                let content = attributedString.attributedSubstring(from: contentRange)
                
                // 创建删除线样式
                let strikethroughContent = NSMutableAttributedString(attributedString: content)
                strikethroughContent.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: NSRange(location: 0, length: strikethroughContent.length))
                strikethroughContent.addAttribute(.foregroundColor, value: NSColor.secondaryLabelColor, range: NSRange(location: 0, length: strikethroughContent.length))
                
                // 替换原文
                attributedString.replaceCharacters(in: fullRange, with: strikethroughContent)
            }
        }
        
        return attributedString
    }
}

// MARK: - String 扩展
extension String {
    func substring(with range: Range<String.Index>) -> String {
        return String(self[range])
    }
}
