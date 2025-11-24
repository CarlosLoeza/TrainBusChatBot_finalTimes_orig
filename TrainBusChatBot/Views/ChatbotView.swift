import SwiftUI
import CoreLocation
import Combine

struct ChatbotView: View {
    @StateObject var chatbotVM: ChatbotViewModel
    @ObservedObject var locationManager: LocationManager

    @FocusState private var isTextFieldFocused: Bool

    init(chatbotVM: ChatbotViewModel, locationManager: LocationManager) {
        _chatbotVM = StateObject(wrappedValue: chatbotVM)
        _locationManager = ObservedObject(wrappedValue: locationManager)
    }

    var body: some View {
        VStack(spacing: 0) {
            
            // MARK: - Messages List (Isolated)
            ChatMessagesList(messages: chatbotVM.messages)
            
            Divider()

            // MARK: - Input Bar (Isolated)
            ChatInputBar(
                text: $chatbotVM.query,
                isFocused: _isTextFieldFocused,
                onSend: sendMessage
            )
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.systemBackground))
        }
        .navigationTitle("BART Chatbot")
        .onTapGesture {
            isTextFieldFocused = false
        }
        .onReceive(
            locationManager.$location
                .removeDuplicates()
                .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
        ) { location in
            chatbotVM.userLocation = location
        }
    }

    // MARK: - Send
    private func sendMessage() {
        guard !chatbotVM.query.isEmpty else { return }
        let text = chatbotVM.query

        Task {
            await chatbotVM.processQuery(text, userLocation: chatbotVM.userLocation)
            chatbotVM.query = ""
        }
    }
}

struct ChatMessagesList: View {
    let messages: [Message]

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(messages) { message in
                        messageRow(message: message)
                            .id(message.id)
                    }
                }
                .padding(.horizontal)
            }
            .onChange(of: messages.count) { _ in
                scrollToBottom(proxy: proxy)
            }
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        guard let last = messages.last else { return }

        // ⚡ Avoid animation during keyboard appearance
        DispatchQueue.main.async {
            proxy.scrollTo(last.id, anchor: .bottom)
        }
    }

    @ViewBuilder
    private func messageRow(message: Message) -> some View {
        Text(message.content)
            .padding(10)
            .background(message.isUser ? Color.blue : Color.gray.opacity(0.3))
            .foregroundColor(message.isUser ? .white : .primary)
            .cornerRadius(10)
            .frame(maxWidth: .infinity, alignment: message.isUser ? .trailing : .leading)
    }
}

struct ChatInputBar: View {
    @Binding var text: String
    @FocusState var isFocused: Bool
    let onSend: () -> Void

    var body: some View {
        HStack {
            TextField("Ask about BART...", text: $text)
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(13)
                .focused($isFocused)

            Button(action: onSend) {
                Text("Send")
                    .padding(10)
                    .background(Color.gray.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(13)
            }
        }
    }
}

struct ChatbotView_Previews: PreviewProvider {
    static var previews: some View {
        let mockBartManager = BartManager(isPreview: true)
        ChatbotView(chatbotVM: ChatbotViewModel(bartManager: mockBartManager), locationManager: LocationManager())
    }
}
