//
//  FavoritesScreen.swift
//  TrainBusChatBotUITests
//
//  This file defines the Page Object for the Favorites screen.
//  It encapsulates all UI elements and interactions specific to the favorites view.
//

import XCTest

struct FavoritesScreen {
    let app: XCUIApplication

    init(app: XCUIApplication) {
        self.app = app
    }

    // MARK: - UI Elements
    /// The collection view displaying the list of favorite routes and stations.
    /// Assumes an accessibilityIdentifier of "favoritesList" in the app.
    var favoritesList: XCUIElement { app.collectionViews["favoritesList"] }

    // MARK: - Actions

    /// Deletes a favorite item by swiping left on its row and tapping the "Delete" button.
    /// - Parameters:
    ///   - query: The query string used to identify the favorite item.
    ///   - type: The type of favorite ("route" or "station").
    /// - Returns: The current FavoritesScreen instance for chaining.
    @discardableResult
    func deleteFavoriteBySwiping(query: String, type: String) -> FavoritesScreen {
        let favoriteIdentifier = "\(type)FavoriteRow_\(query)"
        let favoriteRowText = favoritesList.staticTexts[favoriteIdentifier]
        favoriteRowText.swipeLeft()
        app.buttons["Delete"].tap()
        return self
    }

    /// Deletes a favorite item by tapping its star button (unfavoriting).
    /// - Parameters:
    ///   - query: The query string used to identify the favorite item.
    ///   - type: The type of favorite ("route" or "station").
    /// - Returns: The current FavoritesScreen instance for chaining.
    @discardableResult
    func deleteFavoriteByTappingStar(query: String, type: String) -> FavoritesScreen {
        // Assuming the star button has an identifier like "routeFavoriteRow_query" or "stationFavoriteRow_query"
        // This might need adjustment based on actual app implementation
        let favoriteButton = app.buttons["\(type)FavoriteRow_\(query)"]
        favoriteButton.tap()
        return self
    }

    // MARK: - Assertions / Verifications

    /// Verifies if a favorite with a given query and type exists or not in the list.
    /// - Parameters:
    ///   - query: The query string used to identify the favorite item.
    ///   - type: The type of favorite ("route" or "station").
    ///   - shouldExist: True if the favorite is expected to exist, false otherwise.
    /// - Returns: The current FavoritesScreen instance for chaining.
    @discardableResult
    func verifyFavoriteExists(query: String, type: String, shouldExist: Bool) -> FavoritesScreen {
        let favoriteIdentifier = "\(type)FavoriteRow_\(query)"
        let favoriteRowText = favoritesList.staticTexts[favoriteIdentifier]
        
        if shouldExist {
            XCTAssertTrue(favoriteRowText.waitForExistence(timeout: 5), "Favorite '\(query)' of type '\(type)' should exist.")
        } else {
            XCTAssertFalse(favoriteRowText.exists, "Favorite '\(query)' of type '\(type)' should NOT exist.")
        }
        return self
    }

    /// Verifies that the favorites list is empty.
    /// - Returns: The current FavoritesScreen instance for chaining.
    @discardableResult
    func isFavoritesListEmpty() -> FavoritesScreen {
        let responseIdentifierPredicate = NSPredicate(format: "identifier BEGINSWITH 'routeFavoriteRow_' OR identifier BEGINSWITH 'stationFavoriteRow_'")
        let favoriteTexts = favoritesList.staticTexts.matching(responseIdentifierPredicate)
        XCTAssertEqual(favoriteTexts.count, 0, "Favorites list should be empty of favorites at the start.")
        return self
    }
}
