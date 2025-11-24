import XCTest

final class ChatbotViewUITests: BaseXCUITestCase {

    // This specialized setup runs before every test in THIS file.
    override func setUpWithError() throws {
        // 1. First, run the setup from the parent class (BaseXCUITestCase).
        try super.setUpWithError()

        // 2. Wait for the main UI to be ready before interacting with it.
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 30), "The main tab bar should appear on screen.")

        // 3. Now, add the specific navigation step for this group of tests.
        let mainTabBar = MainTabBar(app: app)
        mainTabBar.tapChatbotTab()
    }

    // MARK: - Screen-Specific Tests

    /// Tests that the chatbot input field is present when the screen loads.
    func testInitialScreenHasInputField() {
        // ARRANGE: The setUpWithError has already navigated us to the chatbot screen.
        let chatbotScreen = ChatbotScreen(app: app)
        
        // ACT & ASSERT: Verify that the input field exists.
        chatbotScreen.verifyMessageInputExists()
    }

    /// Tests that sending a message correctly displays it in the chat history.
    func testSendingAMessageShouldDisplayInChat() {
        // ARRANGE: The app is already on the chatbot screen.
        let chatbotScreen = ChatbotScreen(app: app)
        let message = "Hello, chatbot!"

        // ACT: Send a message.
        chatbotScreen
            .typeMessage(message)
            .tapSendButton()

        // ASSERT: Verify the sent message appears in the chat history.
        XCTAssertTrue(chatbotScreen.isMessageDisplayed(message), "The sent message should be displayed in the chat history.")
    }

    // MARK: - User Journey Tests

    let nextBartToDestinationQuery = "Next daly city bart to colma"
    let nextBartAtStationQuery = "Next Daly City Bart"

    /// Tests the process of adding a favorite route and then removing it by swiping.
    func testAddAndRemoveRoute_bySwiping() throws {
        // ARRANGE: Ensure the app is in a clean state and add the favorite.
        ensureFavoritesAreEmpty()
        addFavoriteFromChatbot(query: nextBartToDestinationQuery, responseText: "Next trains from Daly City towards Colma")
        
        // ACT & ASSERT: Navigate to favorites, verify it exists, then delete by swiping.
        let mainTabBar = MainTabBar(app: app)
        mainTabBar
            .tapFavoritesTab()
            .verifyFavoriteExists(query: nextBartToDestinationQuery, type: "route", shouldExist: true)
            .deleteFavoriteBySwiping(query: nextBartToDestinationQuery, type: "route")
            .verifyFavoriteExists(query: nextBartToDestinationQuery, type: "route", shouldExist: false)
    }
    
    /// Tests the process of adding a favorite station and then removing it by swiping.
    func testAddAndRemoveStation_bySwiping() throws {
        // ARRANGE
        ensureFavoritesAreEmpty()
        addFavoriteFromChatbot(query: nextBartAtStationQuery, responseText: "Next trains for Daly City")

        // ACT & ASSERT
        let mainTabBar = MainTabBar(app: app)
        mainTabBar
            .tapFavoritesTab()
            .verifyFavoriteExists(query: nextBartAtStationQuery, type: "station", shouldExist: true)
            .deleteFavoriteBySwiping(query: nextBartAtStationQuery, type: "station")
            .verifyFavoriteExists(query: nextBartAtStationQuery, type: "station", shouldExist: false)
    }
    
    /// Tests the process of adding a favorite route and then removing it by tapping the star icon.
    func testAddAndRemoveRoute_byTappingStar() throws {
        // ARRANGE
        ensureFavoritesAreEmpty()
        addFavoriteFromChatbot(query: nextBartToDestinationQuery, responseText: "Next trains from Daly City towards Colma")

        // ACT & ASSERT
        let mainTabBar = MainTabBar(app: app)
        mainTabBar
            .tapFavoritesTab()
            .verifyFavoriteExists(query: nextBartToDestinationQuery, type: "route", shouldExist: true)
            .deleteFavoriteByTappingStar(query: nextBartToDestinationQuery, type: "route")
            .verifyFavoriteExists(query: nextBartToDestinationQuery, type: "route", shouldExist: false)
    }

    // MARK: - Refactored Helper Methods

    /// Navigates to the favorites screen and deletes all existing favorites to ensure a clean state.
    private func ensureFavoritesAreEmpty() {
        let favoritesScreen = MainTabBar(app: app).tapFavoritesTab()
        
        // Define a predicate to find only actual favorite items, not headers.
        let favoriteItemPredicate = NSPredicate(format: "identifier BEGINSWITH 'routeFavoriteRow_' OR identifier BEGINSWITH 'stationFavoriteRow_'")
        
        // Loop as long as a real favorite item exists.
        while favoritesScreen.favoritesList.staticTexts.matching(favoriteItemPredicate).firstMatch.exists {
            // Find the first actual favorite item.
            let firstFavorite = favoritesScreen.favoritesList.staticTexts.matching(favoriteItemPredicate).firstMatch
            // Swipe that specific element to delete it.
            firstFavorite.swipeLeft()
            app.buttons["Delete"].tap()
        }
        
        // Final verification that the list is indeed empty of favorites.
        favoritesScreen.isFavoritesListEmpty()
    }

    /// Navigates to the chatbot, enters a query, and taps the favorite button.
    private func addFavoriteFromChatbot(query: String, responseText: String) {
        // This helper now assumes it might need to navigate to the chatbot tab.
        let chatbotScreen = MainTabBar(app: app).tapChatbotTab()
        
        chatbotScreen
            .verifyMessageInputExists()
            .typeMessage(query)
            .tapSendButton()
        
        // Dismiss keyboard
        app.staticTexts[query].tap()

        // Wait for response and assert it appears
        XCTAssertTrue(chatbotScreen.waitForBotResponse(containing: responseText, timeout: 15), "Bot response did not appear in time.")

        // Tap the favorite star in the chat
        chatbotScreen.tapMessageFavoriteButton(forQuery: query)
    }
}
