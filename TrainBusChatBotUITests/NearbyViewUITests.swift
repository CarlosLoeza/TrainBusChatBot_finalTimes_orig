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

// Refactored to use BaseXCUITestCase for consistent setup and teardown.
final class NearbyViewUITests: BaseXCUITestCase {

    /// Define our list of stations to test with their names and simulated coordinates.
    let stationsToTest: [StationTestData] = [
        StationTestData(name: "Powell Street", location: CLLocation(latitude: 37.7840, longitude: -122.4078)),
        StationTestData(name: "Colma", location: CLLocation(latitude: 37.6847, longitude: -122.4597)),
        StationTestData(name: "Daly City", location: CLLocation(latitude: 37.706051, longitude: -122.468807)),
        StationTestData(name: "Montgomery Street", location: CLLocation(latitude: 37.7894, longitude: -122.4010))
    ]
    
    override func setUpWithError() throws {
        // We override the base setup to prevent the app from launching immediately.
        // We will configure and launch it inside the test loop for each station.
        continueAfterFailure = false
    }

    // MARK: - Test Functions

    /// Tests the nearby station functionality for multiple stations by relaunching the app for each location.
    func testNearbyStations_DirectInjection() throws {
        
        for station in stationsToTest {
            // --- 1. ARRANGE: Set the app's launch environment to simulate the location. ---
            app = XCUIApplication()
            app.forceLocation(latitude: station.location.coordinate.latitude, longitude: station.location.coordinate.longitude)
            
            // Handle location permission alert that might appear on first launch.
            addUIInterruptionMonitor(withDescription: "Location Permission") { alert in
                if alert.buttons["Allow While Using App"].exists {
                    alert.buttons["Allow While Using App"].tap()
                    return true
                }
                return false
            }
            
            // Launch the app. The LocationManager will now pick up the simulated location.
            app.launch()
            
            // The app needs to be in the foreground to handle the interruption.
            // A tap is a common way to ensure this.
            app.tap()

            // Perform the test steps for the given station.
            try performNearbyStationTest(station: station)
            
            // Terminate the app to ensure a clean state for the next iteration.
            app.terminate()
        }
         
    }

    // MARK: - Helper Method

    /// Performs the full test flow for a given station in the Nearby Stops view.
    /// - Parameter station: The StationTestData containing the station's name and location.
    private func performNearbyStationTest(station: StationTestData) throws {
        // Add a small delay to allow the UI to settle after launch.
        sleep(2)

        // --- 2. ACT: Navigate to the Nearby tab and trigger location request ---
        let mainTabBar = MainTabBar(app: app)
        let nearbyStopScreen = mainTabBar.tapNearbyTab()
        
        nearbyStopScreen.nearbyBartButton.tap() // Taps the "Find Nearby BART Stops" button
        
        // Debug: Print accessibility hierarchy before checking for the list
        print("\n--- Accessibility Hierarchy Before List Check for \(station.name) ---")
        print(app.debugDescription)
        print("---------------------------------------------------")
        
        // --- 3. ASSERT: Verify the station appears in the list ---
        nearbyStopScreen
            .isNearbyStopsListVisible(timeout: 30)
            .verifyNearbyStopExists(stationName: station.name, shouldExist: true)
            .tapStationRow(stationName: station.name)

        // --- 4. ASSERT: Verify navigation to the details screen ---
        XCTAssertTrue(app.navigationBars["\(station.name)"].waitForExistence(timeout: 5), "Should navigate to the Train List view for \(station.name).")
    }
}

