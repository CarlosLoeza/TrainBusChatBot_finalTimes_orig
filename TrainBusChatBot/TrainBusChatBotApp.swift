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
    @State private var selectedTab = 0
    @State private var nearbyTabID = UUID()
    
    init() {
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
                        NearbyStopsView_ViewModelWrapper(bartManager: bartManager)
                    }
                    .id(nearbyTabID)
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
                        ChatbotView(chatbotVM: chatbotVM)
                    }
                    .tabItem {
                        Label("Chatbot", systemImage: "message.fill")
                    }
                    .tag(2)
                }
                .onChange(of: selectedTab) { oldValue, newValue in
                    print("[DEBUG] Tab changed from \(oldValue) to \(newValue). Current nearbyTabID: \(nearbyTabID)")
                    if oldValue == newValue && oldValue == 0 {
                        print("[DEBUG] Nearby tab tapped while already selected. Resetting ID. Old ID: \(nearbyTabID)")
                        nearbyTabID = UUID()
                        print("[DEBUG] New nearbyTabID: \(nearbyTabID)")
                    }
                }
                .onAppear {
                    let appearance = UITabBarAppearance()
                    appearance.configureWithOpaqueBackground()
                    appearance.backgroundColor = .systemGray6
                    UITabBar.appearance().standardAppearance = appearance
                    UITabBar.appearance().scrollEdgeAppearance = appearance
                }
            } else {
                ProgressView("Loading BART data...")
                    .task {
                        await bartManagerWrapper.loadInitialData()
                    }
            }
        }
    }
}
