import SwiftUI

struct FavoritesView: View {
    @ObservedObject var chatbotVM: ChatbotViewModel
    @Binding var selectedTab: Int
    @State private var isProcessingTap = false // New state variable

    var body: some View {
        List {
            Section(header: Text("Routes")) {
                ForEach(chatbotVM.routeFavorites) { route in
                    HStack {
                        Text(route.name)
                            .onTapGesture {
                                if !isProcessingTap { // Only process if not already processing
                                    isProcessingTap = true // Set flag
                                    Task {
                                        await chatbotVM.processFavorite(route)
                                        selectedTab = 2
                                        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
                                        isProcessingTap = false // Reset flag after delay
                                    }
                                }
                            }
                        Spacer()
                        Button(action: {
                            chatbotVM.toggleFavorite(query: route.query)
                        }) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                        }
                        .accessibilityIdentifier("unfavoriteButton_\(route.name)")
                    }
                    .accessibilityIdentifier("routeFavoriteRow_\(route.name)")
                    .disabled(isProcessingTap) // Disable the row during processing
                }
                .onDelete(perform: deleteRoute)
            }
            
            Section(header: Text("Stations")) {
                ForEach(chatbotVM.stationFavorites) { station in
                    HStack {
                        Text(station.name)
                            .onTapGesture {
                                if !isProcessingTap { // Only process if not already processing
                                    isProcessingTap = true // Set flag
                                    Task {
                                        await chatbotVM.processFavorite(station)
                                        selectedTab = 2
                                        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
                                        isProcessingTap = false // Reset flag after delay
                                    }
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
                    .accessibilityIdentifier("stationFavoriteRow_\(station.name)")
                    .disabled(isProcessingTap) // Disable the row during processing
                }
                .onDelete(perform: deleteStation)
            }
        }
        .accessibilityIdentifier("favoritesList")
        .navigationTitle("Favorites")
        .toolbar {
            EditButton()
        }
    }

    private func deleteRoute(at offsets: IndexSet) {
        chatbotVM.removeRouteFavorite(at: offsets)
    }

    private func deleteStation(at offsets: IndexSet) {
        chatbotVM.removeStationFavorite(at: offsets)
    }
}

