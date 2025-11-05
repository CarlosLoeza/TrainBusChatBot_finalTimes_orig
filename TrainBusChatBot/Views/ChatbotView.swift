
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
                }
                .onChange(of: chatbotVM.messages.count) { newCount in
                    guard newCount > 0 else { return }
                    let lastMessage = chatbotVM.messages.last!

                    if lastMessage.isUser {
                        // User's own message was just sent, scroll to the bottom to show it.
                        scrollTo(id: lastMessage.id, anchor: .bottom, proxy: scrollViewProxy)
                    } else {
                        // Bot has just responded. Scroll to the user's query (the message before the last one)
                        // and anchor it to the top of the view.
                        if chatbotVM.messages.count >= 2 {
                            let userQueryMessageId = chatbotVM.messages[chatbotVM.messages.count - 2].id
                            scrollTo(id: userQueryMessageId, anchor: .top, proxy: scrollViewProxy)
                        } else {
                            // Fallback for the unlikely case where the bot message is the first one.
                            scrollTo(id: lastMessage.id, anchor: .bottom, proxy: scrollViewProxy)
                        }
                    }
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
                    if !chatbotVM.query.isEmpty{
                        Task {
                            await chatbotVM.processQuery(chatbotVM.query, userLocation: chatbotVM.userLocation)
                            chatbotVM.query = ""
                        }
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
    
    private func scrollTo(id: UUID, anchor: UnitPoint, proxy: ScrollViewProxy) {
        DispatchQueue.main.async {
            withAnimation {
                proxy.scrollTo(id, anchor: anchor)
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
