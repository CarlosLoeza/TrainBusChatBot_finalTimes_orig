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

    var body: some Scene {
        WindowGroup {
            if let bartManager = bartManagerWrapper.bartManager {
                TabView {
                    NearbyStopsView_ViewModelWrapper(bartManager: bartManager)
                        .tabItem {
                            Label("Nearby Stops", systemImage: "location.fill")
                        }

                    ChatbotView(chatbotVM: ChatbotViewModel(bartManager: bartManager))
                        .tabItem {
                            Label("Chatbot", systemImage: "message.fill")
                        }
                }
            } else {
                ProgressView("Loading BART data...")
            }
        }
    }
}