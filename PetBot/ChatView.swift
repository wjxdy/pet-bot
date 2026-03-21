import SwiftUI

struct ChatView: View {
    @ObservedObject var viewModel: PetBotViewModel
    @State private var messageText = ""
    @State private var messages: [Message] = []
    
    var body: some View {
        VStack(spacing: 0) {
            // 消息列表
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(messages) { message in
                        MessageBubble(message: message)
                    }
                }
                .padding()
            }
            
            Divider()
            
            // 输入框
            HStack(spacing: 8) {
                TextField("输入消息...", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .disabled(messageText.isEmpty)
            }
            .padding()
        }
        .frame(width: 300, height: 400)
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        
        let userMessage = Message(content: messageText, isUser: true)
        messages.append(userMessage)
        
        viewModel.petState = .thinking
        
        // 模拟 AI 回复
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let botMessage = Message(
                content: "我是 \(viewModel.currentAgent.rawValue)，收到你的消息：\(messageText)",
                isUser: false
            )
            messages.append(botMessage)
            viewModel.petState = .speaking
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                viewModel.petState = .idle
            }
        }
        
        messageText = ""
    }
}

struct Message: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp = Date()
}

struct MessageBubble: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(message.content)
                    .font(.system(size: 14))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(message.isUser ? Color.blue.opacity(0.2) : Color.gray.opacity(0.15))
                    )
                    .foregroundColor(.primary)
            }
            
            if !message.isUser {
                Spacer()
            }
        }
    }
}

#Preview {
    ChatView(viewModel: PetBotViewModel())
}
