import XCTest

class BaseXCUITestCase: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false

        app = XCUIApplication()
        
        // 1. Configure the app
        configureApp(app)
        
        // 2. Launch the app
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
        try super.tearDownWithError()
    }

    /// Centralized place to configure the app's launch arguments and environment variables for UI tests.
    func configureApp(_ app: XCUIApplication) {
        // The argument you were already using
        app.launchArguments.append("--UITesting")

        // Set a default simulated location for tests
        app.forceLocation(latitude: 37.7840, longitude: -122.4078) // Powell Street coordinates

        // You could add more here later, for example:
        // app.launchEnvironment["MOCK_NETWORK_ERRORS"] = "true"
        // app.launchArguments.append("--reset-user-defaults")
    }
}

extension XCUIApplication {
    func forceLocation(latitude: Double, longitude: Double) {
        let coord = "\(latitude),\(longitude)"
        self.launchEnvironment["SIMULATED_LOCATION"] = coord
    }
}
