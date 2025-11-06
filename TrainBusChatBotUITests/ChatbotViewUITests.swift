
import XCTest

final class ChatbotViewUITests: XCTestCase {

    var app: XCUIApplication!
    let nextBartToDestinationQuery = "Next daly city bart to colma"
    let nextBartAtStationQuery = "Next Daly City Bart"
    

    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments.append("--UITesting")
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
        try super.tearDownWithError()
    }

    // --- TEST CASES ---

    func testAddAndRemoveRoute_bySwiping() throws {
        // ARRANGE: Add a favorite route.
        addFavorite(query: nextBartToDestinationQuery, responseText: "Next trains from Daly City towards Colma")
        
        // ACT & ASSERT: Navigate to favorites, verify it exists, then delete by swiping.
        let mainTabBar = MainTabBar(app: app)
        let favoritesScreen = mainTabBar.tapFavoritesTab()
        favoritesScreen.verifyFavoriteExists(query: nextBartToDestinationQuery, type: "route", shouldExist: true)
        favoritesScreen.deleteFavoriteBySwiping(query: nextBartToDestinationQuery, type: "route")
        
        // FINAL ASSERT: Verify it's gone.
        favoritesScreen.verifyFavoriteExists(query: nextBartToDestinationQuery, type: "route", shouldExist: false)
    }
    
    func testAddAndRemoveStation_bySwiping() throws {
        
        // ARRANGE: Add a favorite station.
        addFavorite(query: nextBartAtStationQuery, responseText: "Next trains for Daly City")

        // ACT & ASSERT: Navigate to favorites, verify it exists, then delete by swiping.
        let mainTabBar = MainTabBar(app: app)
        let favoritesScreen = mainTabBar.tapFavoritesTab()
        favoritesScreen.verifyFavoriteExists(query: nextBartAtStationQuery, type: "station", shouldExist: true)
        favoritesScreen.deleteFavoriteBySwiping(query: nextBartAtStationQuery, type: "station")

        // FINAL ASSERT: Verify it's gone.
        favoritesScreen.verifyFavoriteExists(query: nextBartAtStationQuery, type: "station", shouldExist: false)
    }
    
    func testAddAndRemoveRoute_byTappingStar() throws {

        // ARRANGE: Add a favorite route.
        addFavorite(query: nextBartToDestinationQuery, responseText: "Next trains from Daly City towards Colma")

        // ACT & ASSERT: Navigate to favorites, verify it exists, then delete by tapping the star.
        let mainTabBar = MainTabBar(app: app)
        let favoritesScreen = mainTabBar.tapFavoritesTab()
        favoritesScreen.verifyFavoriteExists(query: nextBartToDestinationQuery, type: "route", shouldExist: true)

        // This is the different part: tap the star button on the favorites list to unfavorite.
        favoritesScreen.deleteFavoriteByTappingStar(query: nextBartToDestinationQuery, type: "route")

        // FINAL ASSERT: Verify it's gone.
        favoritesScreen.verifyFavoriteExists(query: nextBartToDestinationQuery, type: "route", shouldExist: false)
    }

    // --- HELPER METHODS ---

    /// Navigates to the chatbot, enters a query, and taps the favorite button.
    private func addFavorite(query: String, responseText: String) {
        // Start on a known tab and ensure favorites are empty.
        let mainTabBar = MainTabBar(app: app)
        let favoritesScreen = mainTabBar.tapFavoritesTab()
        // TODO: Add a method to FavoritesScreen to verify it's empty
        // For now, keeping the direct check:
        let responseIdentifierPredicate = NSPredicate(format: "identifier BEGINSWITH 'routeFavoriteRow_' OR identifier BEGINSWITH 'stationFavoriteRow_'")
        let favoriteTexts = app.collectionViews["favoritesList"].staticTexts.matching(responseIdentifierPredicate)
        XCTAssertEqual(favoriteTexts.count, 0, "Favorites list should be empty of favorites at the start.")

        // Navigate to chatbot and perform query
        let chatbotScreen = mainTabBar.tapChatbotTab()
        XCTAssertTrue(chatbotScreen.messageInput.waitForExistence(timeout: 5))
        chatbotScreen.sendMessage(query)
        
        // Dismiss keyboard (this interaction is still outside the ChatbotScreen's direct responsibility)
        app.staticTexts[query].tap()

        // Wait for response
        XCTAssertTrue(chatbotScreen.waitForBotResponse(containing: responseText, timeout: 15), "Bot response did not appear in time.")

        // Tap the favorite star in the chat
        chatbotScreen.tapFavoriteButton(forQuery: query)
    }

    
}
