
import SwiftUI
import CoreLocation

struct ChatbotView: View {
    @StateObject var chatbotVM: ChatbotViewModel
    @State private var query: String = ""
    @State private var userLocation: CLLocation? // To pass to the chatbotVM
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
                            HStack {
                                if message.isUser {
                                    Spacer()
                                }
                                Text(message.content)
                                    .padding(10)
                                    .background(message.isUser ? Color.blue : Color.gray.opacity(0.2))
                                    .foregroundColor(message.isUser ? .white : .primary)
                                    .cornerRadius(10)
                                if !message.isUser {
                                    Spacer()
                                }
                            }
                            .id(message.id) // Add an ID to each message for scrolling
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
                TextField("Ask about BART...", text: $query)
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(13.0)
                    .focused($isTextFieldFocused)
                    .ignoresSafeArea(.all)
                Button{
                    Task {
                        await chatbotVM.processQuery(query, userLocation: userLocation)
                        query = ""
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
            self.userLocation = location
        }
    }
    
    private func scrollToBottom(scrollViewProxy: ScrollViewProxy) {
        if let lastMessage = chatbotVM.messages.last {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { // Add a small delay
                withAnimation {
                    scrollViewProxy.scrollTo(lastMessage.id, anchor: .bottom)
                }
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
