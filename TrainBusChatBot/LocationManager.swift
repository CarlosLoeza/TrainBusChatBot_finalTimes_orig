
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
        if let coordString = ProcessInfo.processInfo.environment["SIMULATED_LOCATION"] {
            let parts = coordString.split(separator: ",")
            if parts.count == 2,
               let lat = Double(parts[0]),
               let lon = Double(parts[1])
            {
                let mockLocation = CLLocation(latitude: lat, longitude: lon)
                self.locationManager(self.locationManager, didUpdateLocations: [mockLocation])
                return
            }
        }
        
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
