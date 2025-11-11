//
//  MainTabBarUITests.swift
//  TrainBusChatBotUITests
//
//  Created by Carlos on 11/8/25.
//

import XCTest

final class MainTabBarUITests: XCTestCase {
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

    func testNearbyTabTapped(){
        // ARRANGE: Wait for the main tab bar to appear, especially on slow CI machines.
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 30), "The main tab bar should appear on screen.")
        
        // ACT
        let mainTabBar = MainTabBar(app: app)
        let nearbyScreen = mainTabBar.tapNearbyTab()

        // ASSERT
        XCTAssertTrue(nearbyScreen.nearbyBartButton.exists, "The 'Find Nearby BART Stops' button should be visible after tapping the Nearby tab.")
        
        // pass the app to main tab bar
        // use fluent
        // maintab bar
            // verify page exists
            // verify tab exists
            // click tab
            // verify we get the right page
    }
}
