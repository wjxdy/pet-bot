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
        
        // 使用 openclaw agent 命令
        process.arguments = [
            "agent",
            "--agent", agentId,
            "--message", message
        ]
        
        // 禁用插件日志输出
        var env = ProcessInfo.processInfo.environment
        env["OPENCLAW_LOG_LEVEL"] = "silent"
        process.environment = env
        
        let pipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = pipe
        process.standardError = errorPipe
        
        return try await withCheckedThrowingContinuation { continuation in
            process.terminationHandler = { proc in
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                
                var output = String(data: data, encoding: .utf8) ?? ""
                let errorOutput = String(data: errorData, encoding: .utf8) ?? ""
                
                // 过滤掉插件日志行
                let lines = output.components(separatedBy: .newlines)
                let filteredLines = lines.filter { line in
                    !line.contains("[plugins]") && 
                    !line.contains("Registered") &&
                    !line.contains("🦞 OpenClaw") &&
                    !line.isEmpty
                }
                output = filteredLines.joined(separator: "\n")
                
                if proc.terminationStatus == 0 {
                    AppLogger.success("Agent 响应成功，长度: \(output.count)")
                    continuation.resume(returning: output.isEmpty ? "(Agent 已处理)" : output)
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
