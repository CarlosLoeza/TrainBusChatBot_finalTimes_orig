//
//  TrainListViewUITests.swift
//  TrainBusChatBotUITests
//
//  This file contains UI tests for the Train List view, focusing on
//  verifying the visibility of the train schedule list.
//

import XCTest

final class TrainListViewUITests: XCTestCase {

    var app: XCUIApplication!

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

    /// Tests that the train list is visible after navigating to the Train List tab.
    func testTrainListVisibility() throws {
        // ACT: Navigate to the Train List tab.
        let mainTabBar = MainTabBar(app: app)
        mainTabBar.tapTrainListTab()
            // ASSERT: Verify the train list is visible.
            .isTrainListVisible()
    }
}
