// APIService.swift
// API 服务层 - 使用 OpenClaw CLI

import Foundation

protocol APIServiceProtocol {
    func sendMessage(_ message: String, agentId: String) async throws -> String
    func sendMessageStreaming(_ message: String, agentId: String, onChunk: @escaping (String) async -> Void) async throws
}

enum APIError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case serverError(Int, String)
    case decodingError
    case cliError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的 URL"
        case .networkError(let error):
            return "网络错误: \(error.localizedDescription)"
        case .invalidResponse:
            return "无效的响应"
        case .serverError(let code, let message):
            return "服务器错误 (\(code)): \(message)"
        case .decodingError:
            return "解析响应失败"
        case .cliError(let msg):
            return "CLI 错误: \(msg)"
        }
    }
}

actor OpenClawAPIService: APIServiceProtocol {
    static let shared = OpenClawAPIService()
    
    func sendMessage(_ message: String, agentId: String) async throws -> String {
        return try await callOpenClawAgent(message: message, agentId: agentId)
    }
    
    /// 流式发送消息（模拟打字机效果）
    func sendMessageStreaming(_ message: String, agentId: String, onChunk: @escaping (String) async -> Void) async throws {
        // 确保每次调用都是独立的
        let fullResponse = try await callOpenClawAgent(message: message, agentId: agentId)
        
        // 检查响应是否为空或异常
        if fullResponse.isEmpty || fullResponse == "(无回复)" {
            await onChunk("抱歉，没有收到有效回复。")
            return
        }
        
        // 模拟打字机效果 - 按字符或单词流式输出
        let words = fullResponse.components(separatedBy: .whitespacesAndNewlines)
        var outputBuffer = ""
        
        for (index, word) in words.enumerated() {
            outputBuffer += word
            if index < words.count - 1 {
                outputBuffer += " "
            }
            
            // 每 1-3 个字符发送一次
            if outputBuffer.count >= 2 || index == words.count - 1 {
                await onChunk(outputBuffer)
                outputBuffer = ""
                
                // 控制打字速度
                let delay = UInt64.random(in: 10_000_000...30_000_000) // 10-30ms
                try? await Task.sleep(nanoseconds: delay)
            }
        }
        
        // 发送剩余内容
        if !outputBuffer.isEmpty {
            await onChunk(outputBuffer)
        }
    }
    
    private func callOpenClawAgent(message: String, agentId: String) async throws -> String {
        AppLogger.info("调用 OpenClaw agent: \(agentId)")
        
        // 使用配置中的 openclaw 路径
        let openclawPath = AppConfiguration.openclawPath
        let executablePath: String
        if openclawPath.hasPrefix("~") {
            executablePath = openclawPath.replacingOccurrences(of: "~", with: NSHomeDirectory()) + "/bin/openclaw"
        } else {
            executablePath = openclawPath + "/bin/openclaw"
        }
        
        // 检查文件是否存在，回退到系统路径
        let finalPath = FileManager.default.fileExists(atPath: executablePath) ? executablePath : "/usr/local/bin/openclaw"
        
        AppLogger.info("使用 OpenClaw 路径: \(finalPath)")
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: finalPath)
        
        process.arguments = [
            "agent",
            "--agent", agentId,
            "--message", message,
            "--timeout", "30"
        ]
        
        // 设置环境变量
        var env = ProcessInfo.processInfo.environment
        // 确保 PATH 包含必要的目录
        let currentPath = env["PATH"] ?? ""
        env["PATH"] = "/usr/local/bin:/usr/bin:/bin:/opt/homebrew/bin:" + currentPath
        process.environment = env
        
        let pipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = pipe
        process.standardError = errorPipe
        
        return try await withTimeout(seconds: 35) {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
                process.terminationHandler = { proc in
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                    
                    let output = String(data: data, encoding: .utf8) ?? ""
                    let errorOutput = String(data: errorData, encoding: .utf8) ?? ""
                    
                    // 智能提取响应内容
                    let response = Self.extractResponse(from: output)
                    
                    if proc.terminationStatus == 0 {
                        AppLogger.success("Agent 响应成功")
                        continuation.resume(returning: response.isEmpty ? "(无回复)" : response)
                    } else {
                        AppLogger.error("Agent 失败: \(errorOutput)")
                        continuation.resume(throwing: APIError.cliError(errorOutput))
                    }
                }
                
                do {
                    try process.run()
                } catch {
                    continuation.resume(throwing: APIError.cliError(error.localizedDescription))
                }
            }
        }
    }
    
    private static func extractResponse(from output: String) -> String {
        let lines = output.components(separatedBy: .newlines)
        var contentLines: [String] = []
        var foundContent = false
        
        for line in lines {
            // 跳过插件日志行
            if line.contains("[plugins]") || 
               line.contains("Registered") ||
               line.contains("🦞 OpenClaw") ||
               line.contains("Loading ") {
                continue
            }
            
            // 如果遇到非空行，开始收集内容
            if !line.trimmingCharacters(in: .whitespaces).isEmpty {
                foundContent = true
            }
            
            // 收集所有内容行（包括空行，但不包括开头的空行）
            if foundContent {
                contentLines.append(line)
            }
        }
        
        // 移除末尾的空行
        while let last = contentLines.last, last.trimmingCharacters(in: .whitespaces).isEmpty {
            contentLines.removeLast()
        }
        
        return contentLines.joined(separator: "\n")
    }
    
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw APIError.cliError("请求超时")
            }
            
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
}
