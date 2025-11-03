import SwiftUI

struct FavoritesView: View {
    @ObservedObject var chatbotVM: ChatbotViewModel
    @Binding var selectedTab: Int

    var body: some View {
        NavigationView {
            List {
                ForEach(chatbotVM.favoriteRoutes) { route in
                    HStack {
                        Text(route.query)
                            .onTapGesture {
                                Task {
                                    await chatbotVM.processQuery(route.query, userLocation: chatbotVM.userLocation)
                                    selectedTab = 1 // Switch to ChatbotView
                                }
                            }
                        Spacer()
                        Button(action: {
                            chatbotVM.toggleFavorite(query: route.query)
                        }) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                        }
                    }
                }
                .onDelete(perform: delete)
            }
            .navigationTitle("Favorite Routes")
            .toolbar {
                EditButton()
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        chatbotVM.removeFavorite(at: offsets)
    }
}
