//
//  TrainListScreen.swift
//  TrainBusChatBotUITests
//
//  This file defines the Page Object for the Train List screen.
//  It encapsulates all UI elements and interactions specific to the train list view.
//

import XCTest

struct TrainListScreen {
    let app: XCUIApplication

    init(app: XCUIApplication) {
        self.app = app
    }

    // MARK: - UI Elements

    /// The table view displaying the list of trains.
    /// Assumes an accessibilityIdentifier of "trainList" in the app.
    var trainList: XCUIElement { app.tables["trainList"] }

    // MARK: - Assertions / Verifications

    /// Checks if the train list table is visible.
    /// - Parameter timeout: The maximum time to wait for the list to appear.
    /// - Returns: The current TrainListScreen instance for chaining.
    @discardableResult
    func isTrainListVisible(timeout: TimeInterval = 5) -> TrainListScreen {
        XCTAssertTrue(trainList.waitForExistence(timeout: timeout), "Train list should be visible.")
        return self
    }

    // Add more methods as needed for interactions on the Train List screen
    // e.g., func tapTrain(named: String) -> TrainDetailsScreen
}
