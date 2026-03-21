// APIService.swift
// API 服务层 - 使用 OpenClaw CLI

import Foundation

protocol APIServiceProtocol {
    func sendMessage(_ message: String, agentId: String) async throws -> String
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
    
    private func callOpenClawAgent(message: String, agentId: String) async throws -> String {
        AppLogger.info("调用 OpenClaw agent: \(agentId)")
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/local/bin/openclaw")
        
        process.arguments = [
            "agent",
            "--agent", agentId,
            "--message", message,
            "--timeout", "30"
        ]
        
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
