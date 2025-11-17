
import Foundation
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var location: CLLocation?

    override init() {
        super.init()
        locationManager.delegate = self
    }

    func requestLocation() {
        print("[CI DEBUG] requestLocation() called.")
        
        // --- Direct Injection for UI Tests ---
        if let coordString = ProcessInfo.processInfo.environment["SIMULATED_LOCATION"] {
            print("[CI DEBUG] SIMULATED_LOCATION found: \(coordString)")
            let parts = coordString.split(separator: ",")
            if parts.count == 2,
               let lat = Double(parts[0]),
               let lon = Double(parts[1])
            {
                let mockLocation = CLLocation(latitude: lat, longitude: lon)
                // Directly call the delegate method to bypass the system's location manager
                self.locationManager(self.locationManager, didUpdateLocations: [mockLocation])
                return
            }
        }
        // --- End Direct Injection ---
        
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("[CI DEBUG] LocationManager didUpdateLocations: Received location - \(locations.first?.description ?? "nil")")
        location = locations.first
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("[CI DEBUG] LocationManager didFailWithError: \(error.localizedDescription)")
    }
}
