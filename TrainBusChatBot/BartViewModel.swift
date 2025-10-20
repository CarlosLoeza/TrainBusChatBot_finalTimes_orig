
import Foundation
import CoreLocation

@MainActor
class BartViewModel: ObservableObject {
    
    @Published var nearbyStops: [BartManager.Stop] = []
    @Published var nearestStopDistance: CLLocationDistance? 
    @Published var isLoadingStops: Bool = false 
    
    private let bartManager: BartManager

    // Main initializer for actual app use
    init(bartManager: BartManager) {
        self.bartManager = bartManager
    }
    
    // Initializer for previews with mock data
    init(mockStops: [BartManager.Stop] = [], mockDistance: CLLocationDistance? = nil) {
        // Create a dummy BartManager for the preview context
        // This BartManager won't actually load data asynchronously
        self.bartManager = BartManager(isPreview: true)
        self.nearbyStops = mockStops
        self.nearestStopDistance = mockDistance
        self.isLoadingStops = false
    }
    
    func findNearbyStops(from location: CLLocation, radius: CLLocationDistance) async {
        isLoadingStops = true 
        let foundStops = await bartManager.findNearbyStops(from: location, radius: radius)
        self.nearbyStops = foundStops
        
        if let firstStop = foundStops.first {
            let stopLocation = CLLocation(latitude: Double(firstStop.stop_lat) ?? 0, longitude: Double(firstStop.stop_lon) ?? 0)
            self.nearestStopDistance = location.distance(from: stopLocation)
        } else {
            self.nearestStopDistance = nil
        }
        isLoadingStops = false 
    }
    
    // Temporary function to test specific coordinates
    func testNearbyStops(latitude: Double, longitude: Double, radius: CLLocationDistance) async {
        let testLocation = CLLocation(latitude: latitude, longitude: longitude)
        let foundStops = await bartManager.findNearbyStops(from: testLocation, radius: radius)
        print("--- Test Nearby Stops --- ")
        if foundStops.isEmpty {
            print("No stops found for test coordinates.")
        } else {
            for stop in foundStops {
                let stopLocation = CLLocation(latitude: Double(stop.stop_lat) ?? 0, longitude: Double(stop.stop_lon) ?? 0)
                let distance = testLocation.distance(from: stopLocation)
                print("Test Stop: \(stop.stop_name), Distance: \(distance) meters")
            }
        }
        print("-------------------------")
    }
}
