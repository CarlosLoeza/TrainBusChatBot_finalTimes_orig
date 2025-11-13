//
//  NearbyViewUITests.swift
//  TrainBusChatBotUITests
//
//  This file contains UI tests for the Nearby Stops view, focusing on
//  verifying the display and interaction with nearby BART stations based on simulated location.
//

import XCTest
import CoreLocation

/// Defines a struct to hold test data for each station, including name and location.
struct StationTestData {
    let name: String
    let location: CLLocation
}

final class NearbyViewUITests: XCTestCase {

    var app: XCUIApplication!
    /// Define our list of stations to test with their names and simulated coordinates.
    let stationsToTest: [StationTestData] = [
        StationTestData(name: "Powell Street", location: CLLocation(latitude: 37.7840, longitude: -122.4078)),
        StationTestData(name: "Colma", location: CLLocation(latitude: 37.6847, longitude: -122.4597)),
        StationTestData(name: "Daly City", location: CLLocation(latitude: 37.706051, longitude: -122.468807)),
        StationTestData(name: "Montgomery Street", location: CLLocation(latitude: 37.7894, longitude: -122.4010))
    ]
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        // Stop tests immediately if a failure occurs.
        continueAfterFailure = false
        // Initialize the XCUIApplication instance for the app under test.
        app = XCUIApplication()
        // Add launch arguments to configure the app for UI testing (e.g., mocking data).
        app.launchArguments.append("--UITesting")

        // Add a monitor to automatically handle the location permission alert.
        // This is crucial for running tests on clean CI machines.
        addUIInterruptionMonitor(withDescription: "Location Permissions") { (alert) -> Bool in
            if alert.buttons["Allow While Using App"].exists {
                alert.buttons["Allow While Using App"].tap()
                return true // We handled the alert.
            }
            return false // We did not handle this alert.
        }
        
        // Launch the application.
        app.launch()
        
        // Add a tap to handle system alerts like location permissions.
        // This is often needed on CI to trigger the interruption monitor.
        app.tap()
    }

    override func tearDownWithError() throws {
        // Clean up the app instance after each test.
        app = nil
        try super.tearDownWithError()
    }

    // MARK: - Test Functions for Each Station

    /// Tests the nearby station functionality for Powell Street.
    func testNearby_PowellStreet() throws {
        try performNearbyStationTest(station: stationsToTest[0])
    }

    /// Tests the nearby station functionality for Colma.
    func testNearby_Colma() throws {
        try performNearbyStationTest(station: stationsToTest[1])
    }

    /// Tests the nearby station functionality for Daly City.
    func testNearby_DalyCity() throws {
        try performNearbyStationTest(station: stationsToTest[2])
    }

    /// Tests the nearby station functionality for Montgomery Street.
    func testNearby_MontgomeryStreet() throws {
        try performNearbyStationTest(station: stationsToTest[3])
    }

    // MARK: - Helper Method

    /// Performs the full test flow for a given station in the Nearby Stops view.
    /// - Parameter station: The StationTestData containing the station's name and location.
    private func performNearbyStationTest(station: StationTestData) throws {
        // --- 1. ARRANGE: Set the device's simulated location. ---
        XCUIDevice.shared.location = XCUILocation(location: station.location)

        // Add a small delay to allow the simulated location to propagate.
        // This helps prevent race conditions on slower CI machines.
        sleep(2)

        // --- 2. ACT: Navigate to the Nearby tab and trigger location request ---
        let mainTabBar = MainTabBar(app: app)
        let nearbyStopScreen = mainTabBar.tapNearbyTab()
        
        nearbyStopScreen.nearbyBartButton.tap() // Taps the "Find Nearby BART Stops" button
        
        // Debug: Print accessibility hierarchy before checking for the list
        print("\n--- Accessibility Hierarchy Before List Check ---")
        print(app.debugDescription)
        print("---------------------------------------------------")
        nearbyStopScreen
            .isNearbyStopsListVisible(timeout: 30) // Increased timeout for slower CI environment
            .verifyNearbyStopExists(stationName: station.name, shouldExist: true)
            .tapStationRow(stationName: station.name)

        // --- 5. ASSERT: Verify navigation to the details screen ---
        // The destination screen should have a navigation bar with the title of the station.
        XCTAssertTrue(app.navigationBars["\(station.name)"].waitForExistence(timeout: 5), "Should navigate to the Train List view for \(station.name).")
    }
}
