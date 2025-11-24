//
//  TrainBusChatBotApp.swift
//  TrainBusChatBot
//
//  Created by Carlos on 10/15/25.
//

import SwiftUI

@main
struct TrainBusChatBotApp: App {
    @StateObject private var bartManagerWrapper = BartManagerWrapper()
    @StateObject private var locationManager = LocationManager()
    @State private var selectedTab = 0
    
    init() {
        print("[Debug] TrainBusChatBotApp init")
        if ProcessInfo.processInfo.arguments.contains("--UITesting") {
            UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        }
    }

    var body: some Scene {
        WindowGroup {
            if let bartManager = bartManagerWrapper.bartManager {
                let chatbotVM = ChatbotViewModel(bartManager: bartManager)
                TabView(selection: $selectedTab) {
                    NavigationStack {
                        NearbyStopsView_ViewModelWrapper(bartManager: bartManager, locationManager: locationManager)
                    }
                    .tabItem {
                        Label("Nearby", systemImage: "location.fill")
                    }
                    .tag(0)
                    
                    NavigationStack {
                        FavoritesView(chatbotVM: chatbotVM, selectedTab: $selectedTab)
                    }
                    .tabItem {
                        Label("Favorites", systemImage: "star.fill")
                    }
                    .tag(1)

                    NavigationStack {
                        ChatbotView(chatbotVM: chatbotVM, locationManager: locationManager)
                    }
                    .tabItem {
                        Label("Chatbot", systemImage: "message.fill")
                    }
                    .tag(2)
                }
                .onAppear {
                    locationManager.requestLocation()
                    let appearance = UITabBarAppearance()
                    appearance.configureWithOpaqueBackground()
                    appearance.backgroundColor = .systemGray6
                    UITabBar.appearance().standardAppearance = appearance
                    UITabBar.appearance().scrollEdgeAppearance = appearance
                }
            } else {
                ProgressView("Loading BART data...")
                    .onAppear {
                        bartManagerWrapper.loadInitialData()
                    }
            }
        }
    }
}
