
//
//  ChatbotViewUITests.swift
//  TrainBusChatBotUITests
//
//  This file contains UI tests for the Chatbot view, focusing on
//  adding and removing favorite routes and stations via chatbot interactions.
//

import XCTest

final class ChatbotViewUITests: XCTestCase {

    var app: XCUIApplication!
    let nextBartToDestinationQuery = "Next daly city bart to colma"
    let nextBartAtStationQuery = "Next Daly City Bart"
    

    override func setUpWithError() throws {
        try super.setUpWithError()
        // Stop tests immediately if a failure occurs.
        continueAfterFailure = false
        // Initialize the XCUIApplication instance for the app under test.
        app = XCUIApplication()
        // Add launch arguments to configure the app for UI testing (e.g., mocking data).
        app.launchArguments.append("--UITesting")
        // Launch the application.
        app.launch()
    }

    override func tearDownWithError() throws {
        // Clean up the app instance after each test.
        app = nil
        try super.tearDownWithError()
    }

    // MARK: - Test Cases

    /// Tests the process of adding a favorite route and then removing it by swiping.
    func testAddAndRemoveRoute_bySwiping() throws {
        // ARRANGE: Add a favorite route using the helper method.
        addFavorite(query: nextBartToDestinationQuery, responseText: "Next trains from Daly City towards Colma")
        
        // ACT & ASSERT: Navigate to favorites, verify it exists, then delete by swiping.
        let mainTabBar = MainTabBar(app: app)
        mainTabBar
            .tapFavoritesTab()
            .verifyFavoriteExists(query: nextBartToDestinationQuery, type: "route", shouldExist: true)
            .deleteFavoriteBySwiping(query: nextBartToDestinationQuery, type: "route")
            // FINAL ASSERT: Verify it's gone.
            .verifyFavoriteExists(query: nextBartToDestinationQuery, type: "route", shouldExist: false)
    }
    
    /// Tests the process of adding a favorite station and then removing it by swiping.
    func testAddAndRemoveStation_bySwiping() throws {
        
        // ARRANGE: Add a favorite station using the helper method.
        addFavorite(query: nextBartAtStationQuery, responseText: "Next trains for Daly City")

        // ACT & ASSERT: Navigate to favorites, verify it exists, then delete by swiping.
        let mainTabBar = MainTabBar(app: app)
        mainTabBar
            .tapFavoritesTab()
            .verifyFavoriteExists(query: nextBartAtStationQuery, type: "station", shouldExist: true)
            .deleteFavoriteBySwiping(query: nextBartAtStationQuery, type: "station")
            // FINAL ASSERT: Verify it's gone.
            .verifyFavoriteExists(query: nextBartAtStationQuery, type: "station", shouldExist: false)
    }
    
    /// Tests the process of adding a favorite route and then removing it by tapping the star icon.
    func testAddAndRemoveRoute_byTappingStar() throws {

        // ARRANGE: Add a favorite route using the helper method.
        addFavorite(query: nextBartToDestinationQuery, responseText: "Next trains from Daly City towards Colma")

        // ACT & ASSERT: Navigate to favorites, verify it exists, then delete by tapping the star.
        let mainTabBar = MainTabBar(app: app)
        mainTabBar
            .tapFavoritesTab()
            .verifyFavoriteExists(query: nextBartToDestinationQuery, type: "route", shouldExist: true)
            .deleteFavoriteByTappingStar(query: nextBartToDestinationQuery, type: "route")
            // FINAL ASSERT: Verify it's gone.
            .verifyFavoriteExists(query: nextBartToDestinationQuery, type: "route", shouldExist: false)
    }

    // MARK: - Helper Methods

    /// Navigates to the chatbot, enters a query, and taps the favorite button.
    /// This helper ensures the app starts with an empty favorites list before adding a new favorite.
    /// - Parameters:
    ///   - query: The query string to enter into the chatbot.
    ///   - responseText: The expected text in the bot's response.
    private func addFavorite(query: String, responseText: String) {
        // Start on a known tab and ensure favorites are empty.
        let mainTabBar = MainTabBar(app: app)
        mainTabBar
            .tapFavoritesTab()
            .isFavoritesListEmpty()

        // Navigate to chatbot and perform query
        let chatbotScreen = mainTabBar.tapChatbotTab()
        chatbotScreen
            .verifyMessageInputExists() // Ensure the input field is ready
            .typeMessage(query)
            .tapSendButton()
            // dismiss keyboard
            // wait for bot response
            // tap message favorite button
        
        // Dismiss keyboard (this interaction is still outside the ChatbotScreen's direct responsibility)
        app.staticTexts[query].tap()

        // Wait for response
        XCTAssertTrue(chatbotScreen.waitForBotResponse(containing: responseText, timeout: 15), "Bot response did not appear in time.")

        // Tap the favorite star in the chat
        chatbotScreen.tapMessageFavoriteButton(forQuery: query)
    }
}
