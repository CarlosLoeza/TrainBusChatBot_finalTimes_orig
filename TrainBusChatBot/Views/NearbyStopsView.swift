//
//  NearbyStopsView.swift
//  TrainBusChatBot
//
//  Created by Carlos on 10/15/25.
//

import SwiftUI
import CoreLocation

struct NearbyStopsView: View {
    @StateObject var bartViewModel: BartViewModel
    @StateObject private var locationManager = LocationManager()
    
    var body: some View {
        NavigationView {
            VStack {
                Button("Find Nearby BART Stops") {
                    locationManager.requestLocation()
                }
                
                if bartViewModel.isLoadingStops {
                    ProgressView("Finding nearby stops...")
                } else if let location = locationManager.location {
//                    Text("Your location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
                    
                    if let distance = bartViewModel.nearestStopDistance {
                        Text("Distance to nearest stop: \(String(format: "%.2f", distance)) meters")
                    }
                    
                    if bartViewModel.nearbyStops.isEmpty {
                        Text("No nearby BART stops found.")
                    } else {
                        List(bartViewModel.nearbyStops) { stop in
                            // Create a Station object from BartManager.Stop
                            let station = Station(abbr: stop.bartAbbr ?? "", name: stop.stop_name)
                            NavigationLink(destination: TrainListView(station: station)) {
                                VStack(alignment: .leading) {
                                    Text(stop.stop_name)
                                        .font(.headline)
                                    Text("ID: \(stop.stop_id)")
                                        .font(.subheadline)
                                }
                            }
                        }
                    }
                } else {
                    Text("Tap 'Find Nearby BART Stops' to get your location.")
                }
                
                Spacer()
            }
            .navigationTitle("Nearby BART")
            .onReceive(locationManager.$location) { location in
                print("onReceive triggered. Location: \(location?.coordinate.latitude ?? 0), \(location?.coordinate.longitude ?? 0)")
                guard let location = location else {
                    bartViewModel.isLoadingStops = false // Stop loading if location is nil
                    return
                }
                Task {
                    await bartViewModel.findNearbyStops(from: location, radius: 1000)
                }
            }
        }
    }
}

struct NearbyStopsView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a mock BartViewModel for the preview
        // Since BartViewModel has an async initializer, we need to create a dummy one for previews
        // This will not actually load data, but will allow the preview to compile.
        // For a more realistic preview, you would create a mock BartViewModel that returns sample data.
        NearbyStopsView(bartViewModel: BartViewModel(mockStops: [
            BartManager.Stop(stop_id: "1", stop_code: "1", stop_name: "Mock Stop 1", stop_lat: "37.7", stop_lon: "-122.4", zone_id: "1", stop_desc: "", stop_url: "", location_type: "0", parent_station: "", stop_timezone: "", wheelchair_boarding: "0", platform_code: ""),
            BartManager.Stop(stop_id: "2", stop_code: "2", stop_name: "Mock Stop 2", stop_lat: "37.8", stop_lon: "-122.5", zone_id: "1", stop_desc: "", stop_url: "", location_type: "0", parent_station: "", stop_timezone: "", wheelchair_boarding: "0", platform_code: "")
        ], mockDistance: 100.0))
    }
}
