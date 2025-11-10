//
//  MainTabBar.swift
//  TrainBusChatBotUITests
//
//  This file defines the Page Object for the Main Tab Bar.
//  It encapsulates navigation actions between the primary sections of the application.
//

import XCTest

struct MainTabBar {
    let app: XCUIApplication

    init(app: XCUIApplication) {
        self.app = app
    }

    // MARK: - UI Elements

    /// The button for the "Chatbot" tab.
    /// Assumes the button has the label "Chatbot". Marked private as interaction is via tapChatbotTab().
    private var chatbotTabButton: XCUIElement { app.tabBars.buttons["Chatbot"] }

    /// The button for the "Favorites" tab.
    /// Assumes the button has the label "Favorites". Marked private as interaction is via tapFavoritesTab().
    private var favoritesTabButton: XCUIElement { app.tabBars.buttons["Favorites"] }

    /// The button for the "Nearby" tab.
    /// Assumes the button has the label "Nearby". Marked private as interaction is via tapNearbyTab().
    private var nearbyTabButton: XCUIElement { app.tabBars.buttons["Nearby"] }

    /// The button for the "TrainList" tab.
    /// Assumes the button has the label "TrainList".
    var trainListTabButton: XCUIElement { app.tabBars.buttons["TrainList"] }

    // MARK: - Actions

    /// Taps the "Chatbot" tab button and returns a ChatbotScreen Page Object.
    /// - Returns: An instance of ChatbotScreen.
    @discardableResult
    func tapChatbotTab() -> ChatbotScreen {
        chatbotTabButton.tap()
        return ChatbotScreen(app: app)
    }

    /// Taps the "Favorites" tab button and returns a FavoritesScreen Page Object.
    /// - Returns: An instance of FavoritesScreen.
    @discardableResult
    func tapFavoritesTab() -> FavoritesScreen {
        favoritesTabButton.tap()
        return FavoritesScreen(app: app)
    }

    /// Taps the "Nearby" tab button and returns a NearbyStopsScreen Page Object.
    /// - Returns: An instance of NearbyStopsScreen.
    @discardableResult
    func tapNearbyTab() -> NearbyStopsScreen {
        nearbyTabButton.tap()
        return NearbyStopsScreen(app: app)
    }

    /// Taps the "TrainList" tab button and returns a TrainListScreen Page Object.
    /// - Returns: An instance of TrainListScreen.
    @discardableResult
    func tapTrainListTab() -> TrainListScreen {
        trainListTabButton.tap()
        return TrainListScreen(app: app)
    }
    
    func verifyTabExists(tabIdentifier: String){
        let tab = app.buttons[tabIdentifier]
        XCTAssert(tab.waitForExistence(timeout: 3), "\(tabIdentifier) does NOT exist")
    }
}
