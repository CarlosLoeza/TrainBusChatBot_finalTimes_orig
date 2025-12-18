//import XCTest
//@testable import TrainBusChatBot
//
//// MARK: - Mock ViewModel
///// A subclass of ChatbotViewModel designed for unit testing.
///// This mock overrides the functions that contain complex logic and network calls,
///// allowing us to test the behavior of other functions in isolation.
//class MockChatbotViewModel: ChatbotViewModel {
//    override func executeConnectingTrainQuery(origin originStation: Station, destination destinationStation: Station) async -> String {
//        // Return a predictable, fake response instantly.
//        return "Fake response for route from \(originStation.name) to \(destinationStation.name)."
//    }
//
//    override func executeNextTrainQuery(station: Station, direction: String) async -> String {
//        // Return a predictable, fake response instantly.
//        return "Fake response for station \(station.name)."
//    }
//}
//
//
//// MARK: - Test Class
//@MainActor
//final class ChatbotViewModelTests: XCTestCase {
//
//    var bartManager: BartManager!
//    var viewModel: MockChatbotViewModel!
//
//    override func setUp() async throws {
//        try await super.setUp()
//        
//        // ARRANGE (Setup)
//        // 1. Use the synchronous initializer for BartManager in tests.
//        bartManager = BartManager(isPreview: true)
//        
//        // 2. Manually add mock station data to the manager.
//        // This is needed because the function we're testing (`processFavorite`)
//        // calls `findStation(byAbbr:)`, which depends on this `stops` array.
//        bartManager.stops = [
//            .init(stop_id: "1", stop_code: "1", stop_name: "Daly City", stop_lat: "", stop_lon: "", zone_id: "", stop_desc: "", stop_url: "", location_type: "", parent_station: "", stop_timezone: "", wheelchair_boarding: "", platform_code: "", bartAbbr: "DALY"),
//            .init(stop_id: "2", stop_code: "2", stop_name: "Powell St", stop_lat: "", stop_lon: "", zone_id: "", stop_desc: "", stop_url: "", location_type: "", parent_station: "", stop_timezone: "", wheelchair_boarding: "", platform_code: "", bartAbbr: "POWL")
//        ]
//        
//        // 3. Initialize our Mock ViewModel with the prepared BartManager.
//        viewModel = MockChatbotViewModel(bartManager: bartManager)
//    }
//
//    override func tearDown() async throws {
//        bartManager = nil
//        viewModel = nil
//        try await super.tearDown()
//    }
//
//    // MARK: - Test Functions
//
//    func testProcessFavorite_forValidRoute_appendsCorrectMessages() async {
//        // ARRANGE
//        let favoriteRoute = FavoriteRoute(
//            id: UUID(),
//            query: "Daly City Bart to Powell",
//            originStationAbbr: "DALY",
//            destinationStationAbbr: "POWL",
//            type: .route,
//            name: "Daly City Bart to Powell",
//            direction: nil
//        )
//        
//        // Clear the initial prompt message to ensure a clean state for the assertion.
//        viewModel.messages.removeAll()
//        
//        // ACT
//        await viewModel.processFavorite(favoriteRoute)
//        
//        // ASSERT
//        // 1. Check that two messages were added (the user's and the bot's).
//        XCTAssertEqual(viewModel.messages.count, 2)
//        
//        // 2. Check that the first message is the user's message.
//        XCTAssertEqual(viewModel.messages.first?.content, "Daly City Bart to Powell")
//        XCTAssertTrue(viewModel.messages.first?.isUser ?? false)
//        
//        // 3. Check that the last message is the bot's response from our MOCK function.
//        XCTAssertEqual(viewModel.messages.last?.content, "Fake response for route from Daly City to Powell St.")
//        XCTAssertFalse(viewModel.messages.last?.isUser ?? true)
//        
//        // 4. Check that the loading indicator was turned off.
//        XCTAssertFalse(viewModel.isLoadingResponse)
//    }
//    
//    func testProcessFavorite_forInvalidRoute_returnsErrorMessage() async {
//        // ARRANGE
//        // Create a favorite with an abbreviation that does not exist in our mock stops data.
//        let invalidFavorite = FavoriteRoute(
//            id: UUID(),
//            query: "Invalid to Powell",
//            originStationAbbr: "INVALID", // This will cause the guard let to fail
//            destinationStationAbbr: "POWL",
//            type: .route,
//            name: "Invalid to Powell",
//            direction: nil
//        )
//        viewModel.messages.removeAll()
//        
//        // ACT
//        await viewModel.processFavorite(invalidFavorite)
//        
//        // ASSERT
//        XCTAssertEqual(viewModel.messages.count, 2)
//        XCTAssertEqual(viewModel.messages.last?.content, "Sorry, there was an error processing this favorite route.")
//        XCTAssertFalse(viewModel.isLoadingResponse)
//    }
//}
