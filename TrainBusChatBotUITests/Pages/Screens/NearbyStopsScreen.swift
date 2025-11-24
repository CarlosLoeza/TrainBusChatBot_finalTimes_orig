//
//  NearbyStopsScreen.swift
//  TrainBusChatBotUITests
//
//  This file defines the Page Object for the Nearby Stops screen.
//  It encapsulates all UI elements and interactions specific to the nearby stops view.
//

import XCTest

struct NearbyStopsScreen {
    let app: XCUIApplication

    init(app: XCUIApplication) {
        self.app = app
    }

    // MARK: - UI Elements

    /// The collection view displaying the list of nearby stations.
    /// Assumes an accessibilityIdentifier of "nearbyStationList" in the app.
    var nearbyStationList: XCUIElement { app.collectionViews["nearbyStationList"] }

    /// The button to trigger the search for nearby BART stops.
    /// Assumes an accessibilityIdentifier of "nearbyStopButton" in the app.
    var nearbyBartButton: XCUIElement { app.buttons["nearbyStopButton"]}
    
    // MARK: - Actions

    /// Taps on a specific station row in the nearby stops list.
    /// - Parameter stationName: The name of the station to tap.
    /// - Returns: The current NearbyStopsScreen instance for chaining.
    @discardableResult
    func tapStationRow(stationName: String) -> NearbyStopsScreen {
        let foundNearbyStopsButton = nearbyStationList.buttons["nearbyStopRow_\(stationName)"]
        XCTAssertTrue(foundNearbyStopsButton.waitForExistence(timeout: 15), "nearbyStopRow_\(stationName), was NOT found")
        foundNearbyStopsButton.tap()
        return self
    }

    /// Taps the first available stop in the nearby stops list.
    /// - Returns: The current NearbyStopsScreen instance for chaining.
    @discardableResult
    func tapFirstStop() -> NearbyStopsScreen {
        nearbyStationList.cells.firstMatch.tap()
        return self
    }

    // MARK: - Assertions / Verifications

    /// Verifies if a specific nearby stop exists in the list.
    /// - Parameters:
    ///   - stationName: The name of the station to verify.
    ///   - shouldExist: True if the station is expected to exist, false otherwise.
    /// - Returns: The current NearbyStopsScreen instance for chaining.
    @discardableResult
    func verifyNearbyStopExists(stationName: String, shouldExist: Bool) -> NearbyStopsScreen {
        let stationNameIdentifier = "nearbyStopRow_\(stationName)"
        let nearbyStopRow = nearbyStationList.buttons[stationNameIdentifier]
        
        if shouldExist{
            XCTAssertTrue(nearbyStopRow.waitForExistence(timeout: 10), "\(stationName) should appear in the nearby stops list.")
        } else {
            XCTAssertFalse(nearbyStopRow.exists, "Nearby stop \(stationName) should NOT exist")
        }
        return self
    }

    /// Checks if the nearby stops list (CollectionView) is visible.
    /// - Parameter timeout: The maximum time to wait for the list to appear.
    /// - Returns: The current NearbyStopsScreen instance for chaining.
    @discardableResult
    func isNearbyStopsListVisible(timeout: TimeInterval = 10) -> NearbyStopsScreen {
        XCTAssertTrue(nearbyStationList.waitForExistence(timeout: timeout), "Nearby stops list should be visible.")
        return self
    }
}
