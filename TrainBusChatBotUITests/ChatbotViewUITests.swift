
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
        app.tabBars.buttons["Favorites"].tap()
        verifyFavoriteExists(query: nextBartToDestinationQuery, type: "route", shouldExist: true)
        
        let favoriteRowText = app.collectionViews["favoritesList"].staticTexts["routeFavoriteRow_\(nextBartToDestinationQuery)"]
        favoriteRowText.swipeLeft()
        app.buttons["Delete"].tap()
        
        // FINAL ASSERT: Verify it's gone.
        verifyFavoriteExists(query: nextBartToDestinationQuery, type: "route", shouldExist: false)
    }
    
    func testAddAndRemoveStation_bySwiping() throws {
        
        // ARRANGE: Add a favorite station.
        addFavorite(query: nextBartAtStationQuery, responseText: "Next trains for Daly City")

        // ACT & ASSERT: Navigate to favorites, verify it exists, then delete by swiping.
        app.tabBars.buttons["Favorites"].tap()
        verifyFavoriteExists(query: nextBartAtStationQuery, type: "station", shouldExist: true)

        let favoriteRowText = app.collectionViews["favoritesList"].staticTexts["stationFavoriteRow_\(nextBartAtStationQuery)"]
        favoriteRowText.swipeLeft()
        app.buttons["Delete"].tap()

        // FINAL ASSERT: Verify it's gone.
        verifyFavoriteExists(query: nextBartAtStationQuery, type: "station", shouldExist: false)
    }
    
    func testAddAndRemoveRoute_byTappingStar() throws {

        
        // ARRANGE: Add a favorite route.
        addFavorite(query: nextBartToDestinationQuery, responseText: "Next trains from Daly City towards Colma")

        // ACT & ASSERT: Navigate to favorites, verify it exists, then delete by tapping the star.
        app.tabBars.buttons["Favorites"].tap()
        verifyFavoriteExists(query: nextBartToDestinationQuery, type: "route", shouldExist: true)

        // This is the different part: tap the star button on the favorites list to unfavorite.
        app.buttons["routeFavoriteRow_\(nextBartToDestinationQuery)"].tap()

        // FINAL ASSERT: Verify it's gone.
        verifyFavoriteExists(query: nextBartToDestinationQuery, type: "route", shouldExist: false)
    }

    // --- HELPER METHODS ---

    /// Navigates to the chatbot, enters a query, and taps the favorite button.
    private func addFavorite(query: String, responseText: String) {
        // Start on a known tab and ensure favorites are empty.
        app.tabBars.buttons["Favorites"].tap()
        let responseIdentifierPredicate = NSPredicate(format: "identifier BEGINSWITH 'routeFavoriteRow_' OR identifier BEGINSWITH 'stationFavoriteRow_'")
        let favoriteTexts = app.collectionViews["favoritesList"].staticTexts.matching(responseIdentifierPredicate)
        XCTAssertEqual(favoriteTexts.count, 0, "Favorites list should be empty of favorites at the start.")

        // Navigate to chatbot and perform query
        app.tabBars.buttons["Chatbot"].tap()
        
        let textField = app.textFields["Ask about BART..."]
        XCTAssertTrue(textField.waitForExistence(timeout: 5))
        textField.tap()
        textField.typeText(query)
        app.buttons["Send"].tap()
        
        // Dismiss keyboard
        app.staticTexts[query].tap()

        // Wait for response
        let responseLabelPredicate = NSPredicate(format: "label BEGINSWITH %@", responseText)
        let responseElement = app.staticTexts.containing(responseLabelPredicate).firstMatch
        XCTAssertTrue(responseElement.waitForExistence(timeout: 15), "Bot response did not appear in time.")

        // Tap the favorite star in the chat
        let favoriteButton = app.buttons["favoriteButton_\(query)"]
        XCTAssertTrue(favoriteButton.waitForExistence(timeout: 5))
        favoriteButton.tap()
    }

    /// Verifies if a favorite with a given query and type exists or not.
    private func verifyFavoriteExists(query: String, type: String, shouldExist: Bool) {
        let favoriteIdentifier = "\(type)FavoriteRow_\(query)"
        let favoriteRowText = app.collectionViews["favoritesList"].staticTexts[favoriteIdentifier]
        
        if shouldExist {
            XCTAssertTrue(favoriteRowText.waitForExistence(timeout: 5), "Favorite '\(query)' of type '\(type)' should exist.")
        } else {
            XCTAssertFalse(favoriteRowText.exists, "Favorite '\(query)' of type '\(type)' should NOT exist.")
        }
    }
}
