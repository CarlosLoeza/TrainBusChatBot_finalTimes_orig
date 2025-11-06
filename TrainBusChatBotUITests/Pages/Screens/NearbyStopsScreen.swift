import XCTest

struct NearbyStopsScreen {
    let app: XCUIApplication

    init(app: XCUIApplication) {
        self.app = app
    }

    // Placeholder for elements and actions specific to the Nearby Stops screen
    var nearbyStopsTable: XCUIElement { app.tables["nearbyStopsTable"] }

    func isNearbyStopsTableVisible(timeout: TimeInterval = 10) -> Bool {
        return nearbyStopsTable.waitForExistence(timeout: timeout)
    }

    func tapFirstStop() {
        nearbyStopsTable.cells.firstMatch.tap()
    }

    // Add more methods as needed for interactions on the Nearby Stops screen
}
