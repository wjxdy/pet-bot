// ChatHistoryStorage.swift
// 聊天记录本地持久化存储

import Foundation

@MainActor
class ChatHistoryStorage {
    static let shared = ChatHistoryStorage()
    
    private let fileManager = FileManager.default
    private var storageDirectory: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("PetBot/ChatHistory")
    }
    
    // 内存缓存
    private var messageCache: [String: [ChatMessage]] = [:]
    
    private init() {
        createStorageDirectoryIfNeeded()
        loadAllHistories()
    }
    
    // MARK: - 公共接口
    
    /// 添加消息到历史记录
    func addMessage(_ message: ChatMessage, for agentId: String) {
        if messageCache[agentId] == nil {
            messageCache[agentId] = []
        }
        messageCache[agentId]?.append(message)
        
        // 清理过期消息
        cleanupExpiredMessages(for: agentId)
        
        // 保存到文件
        saveHistory(for: agentId)
    }
    
    /// 获取指定 Agent 的历史记录
    func getMessages(for agentId: String) -> [ChatMessage] {
        return messageCache[agentId] ?? []
    }
    
    /// 获取所有历史记录
    func getAllHistories() -> [String: [ChatMessage]] {
        return messageCache
    }
    
    /// 清除指定 Agent 的历史记录
    func clearHistory(for agentId: String) {
        messageCache[agentId] = []
        deleteHistoryFile(for: agentId)
    }
    
    /// 清除所有历史记录
    func clearAllHistories() {
        messageCache.removeAll()
        try? fileManager.removeItem(at: storageDirectory)
        createStorageDirectoryIfNeeded()
    }
    
    // MARK: - 私有方法
    
    private func createStorageDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: storageDirectory.path) {
            try? fileManager.createDirectory(at: storageDirectory, withIntermediateDirectories: true)
        }
    }
    
    private func loadAllHistories() {
        guard let files = try? fileManager.contentsOfDirectory(at: storageDirectory, includingPropertiesForKeys: nil) else {
            return
        }
        
        for file in files where file.pathExtension == "json" {
            let agentId = file.deletingPathExtension().lastPathComponent
            if let messages = loadHistoryFromFile(for: agentId) {
                messageCache[agentId] = messages
            }
        }
    }
    
    private func loadHistoryFromFile(for agentId: String) -> [ChatMessage]? {
        let fileURL = storageDirectory.appendingPathComponent("\(agentId).json")
        
        guard let data = try? Data(contentsOf: fileURL) else {
            return nil
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            let messages = try decoder.decode([ChatMessage].self, from: data)
            // 过滤掉过期消息
            return filterExpiredMessages(messages)
        } catch {
            print("[ChatHistoryStorage] 加载历史记录失败: \(error)")
            return nil
        }
    }
    
    private func saveHistory(for agentId: String) {
        guard let messages = messageCache[agentId] else { return }
        
        let fileURL = storageDirectory.appendingPathComponent("\(agentId).json")
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        do {
            let data = try encoder.encode(messages)
            try data.write(to: fileURL)
        } catch {
            print("[ChatHistoryStorage] 保存历史记录失败: \(error)")
        }
    }
    
    private func deleteHistoryFile(for agentId: String) {
        let fileURL = storageDirectory.appendingPathComponent("\(agentId).json")
        try? fileManager.removeItem(at: fileURL)
    }
    
    private func cleanupExpiredMessages(for agentId: String) {
        guard let messages = messageCache[agentId] else { return }
        messageCache[agentId] = filterExpiredMessages(messages)
    }
    
    private func filterExpiredMessages(_ messages: [ChatMessage]) -> [ChatMessage] {
        let retentionHours = AppConfiguration.chatHistoryRetentionHours
        guard retentionHours > 0 else { return messages }
        
        let cutoffDate = Date().addingTimeInterval(-TimeInterval(retentionHours * 3600))
        return messages.filter { $0.timestamp > cutoffDate }
    }
}

// MARK: - ChatMessage 扩展支持 Codable
extension ChatMessage: Codable {
    enum CodingKeys: String, CodingKey {
        case content, isUser, agentName, timestamp
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(content, forKey: .content)
        try container.encode(isUser, forKey: .isUser)
        try container.encode(agentName, forKey: .agentName)
        try container.encode(timestamp, forKey: .timestamp)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        content = try container.decode(String.self, forKey: .content)
        isUser = try container.decode(Bool.self, forKey: .isUser)
        agentName = try container.decodeIfPresent(String.self, forKey: .agentName)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
    }
}
