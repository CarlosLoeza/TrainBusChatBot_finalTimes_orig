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
        let mainTabBar = MainTabBar(app: app)
        
        let nearbyScreen = mainTabBar.tapNearbyTab()
        XCTAssertTrue(nearbyScreen.nearbyBartButton.exists, "Nearby tab view was NOT found")
        
        // pass the app to main tab bar
        // use fluent
        // maintab bar
            // verify page exists
            // verify tab exists
            // click tab
            // verify we get the right page
    }
}
