import XCTest
import CoreLocation

// Define a struct to hold our test data for each station
struct StationTestData {
    let name: String
    let location: CLLocation
}

final class NearbyViewUITests: XCTestCase {

    var app: XCUIApplication!
    // Define our list of stations to test
    let stationsToTest: [StationTestData] = [
        StationTestData(name: "Powell Street", location: CLLocation(latitude: 37.7840, longitude: -122.4078)),
        StationTestData(name: "Colma", location: CLLocation(latitude: 37.6847, longitude: -122.4597)),
        StationTestData(name: "Daly City", location: CLLocation(latitude: 37.706051, longitude: -122.468807)),
        StationTestData(name: "Montgomery Street", location: CLLocation(latitude: 37.7894, longitude: -122.4010))
    ]
    
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

    // --- TEST FUNCTIONS FOR EACH STATION ---

    func testNearby_PowellStreet() throws {
        try performNearbyStationTest(station: stationsToTest[0])
    }

    func testNearby_Colma() throws {
        try performNearbyStationTest(station: stationsToTest[1])
    }

    func testNearby_DalyCity() throws {
        try performNearbyStationTest(station: stationsToTest[2])
    }

    func testNearby_MontgomeryStreet() throws {
        try performNearbyStationTest(station: stationsToTest[3])
    }

    // --- HELPER METHOD ---

    /// Performs the full test flow for a given station.
    private func performNearbyStationTest(station: StationTestData) throws {
        // --- 1. ARRANGE: Set the device's location before launching ---
        XCUIDevice.shared.location = XCUILocation(location: station.location)
        
        // Launch the app with the simulated location.
        app.launch()

        // --- 2. ACT: Navigate to the Nearby tab and trigger location request ---
        let mainTabBar = MainTabBar(app: app)
        app.tabBars.buttons["Nearby"].tap()
        
        // Tap the button to trigger the location request and load nearby stops.
        app.buttons["Find Nearby BART Stops"].tap()

        // --- 3. ASSERT: Verify that the station appears in the list ---
        let nearbyList = app.collectionViews["nearbyStopsList"]
        print("test: \(nearbyList.debugDescription)")
        // Wait for the list itself to exist before trying to find elements within it.
        XCTAssertTrue(nearbyList.waitForExistence(timeout: 10), "The nearby stops list should appear for \(station.name).")

        // The identifier is on the Button, not the StaticText.
        let stationRow = nearbyList.buttons["nearbyStopRow_\(station.name)"]
        
        // Wait up to 10 seconds for the location to be processed and the list to update.
        XCTAssertTrue(stationRow.waitForExistence(timeout: 10), "\(station.name) should appear in the nearby stops list.")

        // --- 4. ACT: Tap the station row ---
        stationRow.tap()

        // --- 5. ASSERT: Verify navigation to the details screen ---
        // The destination screen should have a navigation bar with the title of the station.
        XCTAssertTrue(app.navigationBars["\(station.name)"].waitForExistence(timeout: 5), "Should navigate to the Train List view for \(station.name).")
    }
}
