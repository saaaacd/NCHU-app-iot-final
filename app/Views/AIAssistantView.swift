import SwiftUI
import Combine

struct AIAssistantView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AIAssistantViewModel()
    @StateObject private var inputVM = ChatInputViewModel()
    @EnvironmentObject private var theme: ThemeManager
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 聊天列表
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.messages) { message in
                                ChatBubble(message: message)
                                    .id(message.id)
                            }
                            if viewModel.isTyping {
                                TypingIndicator()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.leading, 12)
                                    .id("TypingIndicator")
                            }
                        }
                        .padding()
                    }
                    .onChange(of: viewModel.messages.count) { _, _ in
                        withAnimation {
                            proxy.scrollTo(viewModel.messages.last?.id, anchor: .bottom)
                        }
                    }
                    .onChange(of: viewModel.isTyping) { _, isTyping in
                        if isTyping {
                            withAnimation {
                                proxy.scrollTo("TypingIndicator", anchor: .bottom)
                            }
                        }
                    }
                }
                
                // 建議問題區塊（只在剛進入對話時顯示）
                if viewModel.messages.count == 1 && !viewModel.isTyping {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(viewModel.suggestedQuestions, id: \.self) { question in
                                Button(action: {
                                    inputVM.inputText = question
                                }) {
                                    Text(question)
                                        .font(.subheadline)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(theme.accent.color.opacity(0.1))
                                        .foregroundColor(theme.accent.color)
                                        .clipShape(Capsule())
                                        .overlay(
                                            Capsule().stroke(theme.accent.color.opacity(0.3), lineWidth: 1)
                                        )
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                // 底部輸入框獨立成元件以避免打字卡頓
                ChatInputView(inputVM: inputVM) { text in
                    viewModel.inputText = text
                    viewModel.sendMessage()
                }
            }
            .navigationTitle("AI 助手")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("關閉") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// 獨立的 ViewModel 管理輸入狀態，避免注音輸入法或 Enter 鍵造成 @State 文字消失的 Bug
class ChatInputViewModel: ObservableObject {
    @Published var inputText: String = ""
}

// 獨立的輸入框元件，避免每次打字觸發外部 ViewModel 更新導致畫面卡頓
struct ChatInputView: View {
    @ObservedObject var inputVM: ChatInputViewModel
    @EnvironmentObject private var theme: ThemeManager
    var onSend: (String) -> Void
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            TextField("輸入問題...", text: $inputVM.inputText, axis: .vertical)
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(20)
                .lineLimit(1...5)
            
            Button(action: {
                let textToSend = inputVM.inputText
                inputVM.inputText = ""
                onSend(textToSend)
            }) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(inputVM.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : theme.accent.color)
            }
            .disabled(inputVM.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .shadow(color: .black.opacity(0.05), radius: 5, y: -2)
    }
}

struct ChatBubble: View {
    let message: ChatMessage
    @EnvironmentObject private var theme: ThemeManager
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
            } else {
                // AI 頭像
                ZStack {
                    Circle()
                        .fill(theme.accent.color.opacity(0.2))
                        .frame(width: 32, height: 32)
                    Image(systemName: "sparkles")
                        .foregroundColor(theme.accent.color)
                        .font(.system(size: 16))
                }
            }
            
            Text(message.content)
                .padding(12)
                .background(message.isUser ? theme.accent.color : Color(.systemGray5))
                .foregroundColor(message.isUser ? .white : .primary)
                .cornerRadius(16)
                .clipShape(ChatBubbleShape(isUser: message.isUser))
            
            if !message.isUser {
                Spacer()
            }
        }
    }
}

struct ChatBubbleShape: Shape {
    let isUser: Bool
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: [
                .topLeft,
                .topRight,
                isUser ? .bottomLeft : .bottomRight
            ],
            cornerRadii: CGSize(width: 16, height: 16)
        )
        return Path(path.cgPath)
    }
}

struct TypingIndicator: View {
    @State private var animationOffset: CGFloat = 0
    @EnvironmentObject private var theme: ThemeManager
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(theme.accent.color)
                    .frame(width: 8, height: 8)
                    .offset(y: animationOffset)
                    .animation(
                        Animation.easeInOut(duration: 0.5)
                            .repeatForever()
                            .delay(0.15 * Double(index)),
                        value: animationOffset
                    )
            }
        }
        .padding(12)
        .background(Color(.systemGray5))
        .cornerRadius(16)
        .clipShape(ChatBubbleShape(isUser: false))
        .onAppear {
            animationOffset = -5
        }
    }
}
