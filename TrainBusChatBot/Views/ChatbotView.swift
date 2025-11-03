
import SwiftUI
import CoreLocation
//
struct ChatbotView: View {
    @StateObject var chatbotVM: ChatbotViewModel
    @State private var keyboardHeight: CGFloat = 0 // New state for keyboard height
    @FocusState private var isTextFieldFocused: Bool
    
    // We need a way to get the user's location for the chatbot
    @StateObject private var locationManager = LocationManager()

    var body: some View {
        VStack {
            ScrollViewReader { scrollViewProxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(chatbotVM.messages) { message in
                            messageRow(message: message)
                                .id(message.id)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, keyboardHeight) // Add padding for keyboard
                }
                .onChange(of: chatbotVM.messages.count) { _ in
                    scrollToBottom(scrollViewProxy: scrollViewProxy)
                }
                .onChange(of: keyboardHeight) { _ in
                    scrollToBottom(scrollViewProxy: scrollViewProxy)
                }
                .onAppear {
                    // Observe keyboard notifications
                    NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notification in
                        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
                        keyboardHeight = keyboardFrame.height
                        scrollToBottom(scrollViewProxy: scrollViewProxy)
                    }
                    NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
                        keyboardHeight = 0
                        scrollToBottom(scrollViewProxy: scrollViewProxy)
                    }
                }
                .onDisappear {
                    NotificationCenter.default.removeObserver(self)
                }
            }
            .onTapGesture {
                isTextFieldFocused = false // dismiss keyboard when tapping anywhere outside
            }
            HStack {
                TextField("Ask about BART...", text: $chatbotVM.query)
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(13.0)
                    .focused($isTextFieldFocused)
                    .ignoresSafeArea(.all)
                Button{
                    Task {
                        await chatbotVM.processQuery(chatbotVM.query, userLocation: chatbotVM.userLocation)
                        chatbotVM.query = ""
                    }
                } label: {
                    Text("Send")
                        .padding()
                        .background(.gray)
                        .cornerRadius(13.0)
                       
                }
                if chatbotVM.isLoadingResponse {
                    ProgressView()
                        .padding(.trailing)
                } else {
                    
                }
            }
            .padding(5) // Keep the padding(5) as it was in the current file
        }
        .navigationTitle("BART Chatbot")
        .onAppear {
            locationManager.requestLocation()
        }
        .onReceive(locationManager.$location) { location in
            chatbotVM.userLocation = location
        }
    }

    @ViewBuilder
    private func messageRow(message: Message) -> some View {
        HStack {
            if message.isUser {
                Spacer()
                HStack {
                    Text(message.content)
                    Button(action: {
                        chatbotVM.toggleFavorite(query: message.content)
                    }) {
                        Image(systemName: chatbotVM.isFavorite(query: message.content) ? "star.fill" : "star")
                            .foregroundColor(.yellow)
                    }
                }
                .padding(10)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            } else {
                Text(message.content)
                    .padding(10)
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.primary)
                    .cornerRadius(10)
                Spacer()
            }
        }
    }
    
    private func scrollToBottom(scrollViewProxy: ScrollViewProxy) {
        guard !chatbotVM.messages.isEmpty else { return }
        let lastMessageId = chatbotVM.messages.last!.id

        DispatchQueue.main.async {
            withAnimation {
                scrollViewProxy.scrollTo(lastMessageId, anchor: .bottom)
            }
        }
    }
}

struct ChatbotView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a mock BartManager for the preview
        let mockBartManager = BartManager(isPreview: true)
        ChatbotView(chatbotVM: ChatbotViewModel(bartManager: mockBartManager))
    }
}
