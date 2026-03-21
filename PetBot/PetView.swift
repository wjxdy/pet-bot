import SwiftUI

struct PetView: View {
    @ObservedObject var viewModel: PetBotViewModel
    @State private var isDragging = false
    @State private var dragOffset: CGSize = .zero
    
    var body: some View {
        VStack(spacing: 12) {
            // 宠物图片（在上）
            PetImageView(state: viewModel.petState)
                .frame(width: 120, height: 120)
                .offset(dragOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            isDragging = true
                            dragOffset = value.translation
                        }
                        .onEnded { _ in
                            isDragging = false
                            withAnimation(.spring()) {
                                dragOffset = .zero
                            }
                        }
                )
            
            // Agent 名称（在脚下）
            AgentNameLabel(agent: viewModel.currentAgent)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(NSColor.windowBackgroundColor))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
}

struct PetImageView: View {
    let state: PetBotViewModel.PetState
    
    var body: some View {
        ZStack {
            // 宠物背景圆圈
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.orange.opacity(0.3), .yellow.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 100, height: 100)
            
            // 宠物表情
            Text(petEmoji)
                .font(.system(size: 60))
                .scaleEffect(state == .speaking ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.3), value: state)
        }
    }
    
    private var petEmoji: String {
        switch state {
        case .idle: return "😺"
        case .listening: return "👂"
        case .thinking: return "🤔"
        case .speaking: return "🗣️"
        }
    }
}

struct AgentNameLabel: View {
    let agent: Agent
    
    var body: some View {
        HStack(spacing: 6) {
            Text(agent.icon)
                .font(.title3)
            Text(agent.rawValue)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.blue.opacity(0.15))
        )
        .overlay(
            Capsule()
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    PetView(viewModel: PetBotViewModel())
}
