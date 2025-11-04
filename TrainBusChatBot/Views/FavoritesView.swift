import SwiftUI

struct FavoritesView: View {
    @ObservedObject var chatbotVM: ChatbotViewModel
    @Binding var selectedTab: Int

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Routes")) {
                    ForEach(chatbotVM.routeFavorites) { route in
                        HStack {
                            Text(route.name)
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
                    .onDelete(perform: deleteRoute)
                }

                Section(header: Text("Stations")) {
                    ForEach(chatbotVM.stationFavorites) { station in
                        HStack {
                            Text(station.name)
                                .onTapGesture {
                                    Task {
                                        await chatbotVM.processQuery(station.query, userLocation: chatbotVM.userLocation)
                                        selectedTab = 1 // Switch to ChatbotView
                                    }
                                }
                            Spacer()
                            Button(action: {
                                chatbotVM.toggleFavorite(query: station.query)
                            }) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                            }
                        }
                    }
                    .onDelete(perform: deleteStation)
                }
            }
            .navigationTitle("Favorite Routes")
            .toolbar {
                EditButton()
            }
        }
    }

    private func deleteRoute(at offsets: IndexSet) {
        chatbotVM.removeRouteFavorite(at: offsets)
    }

    private func deleteStation(at offsets: IndexSet) {
        chatbotVM.removeStationFavorite(at: offsets)
    }
}
