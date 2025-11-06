import XCTest

struct FavoritesScreen {
    let app: XCUIApplication

    init(app: XCUIApplication) {
        self.app = app
    }

    // Placeholder for elements and actions specific to the Favorites screen
    var favoritesList: XCUIElement { app.collectionViews["favoritesList"] }

    func verifyFavoriteExists(query: String, type: String, shouldExist: Bool) {
        let favoriteIdentifier = "\(type)FavoriteRow_\(query)"
        let favoriteRowText = favoritesList.staticTexts[favoriteIdentifier]
        
        if shouldExist {
            XCTAssertTrue(favoriteRowText.waitForExistence(timeout: 5), "Favorite '\(query)' of type '\(type)' should exist.")
        } else {
            XCTAssertFalse(favoriteRowText.exists, "Favorite '\(query)' of type '\(type)' should NOT exist.")
        }
    }

    func deleteFavoriteBySwiping(query: String, type: String) {
        let favoriteIdentifier = "\(type)FavoriteRow_\(query)"
        let favoriteRowText = favoritesList.staticTexts[favoriteIdentifier]
        favoriteRowText.swipeLeft()
        app.buttons["Delete"].tap()
    }

    func deleteFavoriteByTappingStar(query: String, type: String) {
        // Assuming the star button has an identifier like "routeFavoriteRow_query" or "stationFavoriteRow_query"
        // This might need adjustment based on actual app implementation
        let favoriteButton = app.buttons["\(type)FavoriteRow_\(query)"]
        favoriteButton.tap()
    }

    func isFavoritesListEmpty() -> Bool {
        let responseIdentifierPredicate = NSPredicate(format: "identifier BEGINSWITH 'routeFavoriteRow_' OR identifier BEGINSWITH 'stationFavoriteRow_'")
        let favoriteTexts = favoritesList.staticTexts.matching(responseIdentifierPredicate)
        return favoriteTexts.count == 0
    }
}
