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
    @ObservedObject var locationManager: LocationManager
    
    var body: some View {
        VStack {
            findStopsButton
            
            if let location = locationManager.location {
                if bartViewModel.nearbyStops.isEmpty && !bartViewModel.isLoadingStops {
                    Text("No nearby BART stops found.")
                } else {
                    stopList(for: location)
                }
            } else {
                Text("Tap 'Find Nearby BART Stops' to get your location.")
            }
            
            Spacer()
        }
        .navigationTitle("Nearby BART")
        .task(id: locationManager.location) {
            await handleLocationUpdate(locationManager.location)
        }
    }

    @ViewBuilder
    private var findStopsButton: some View {
        Button(action: {
            locationManager.requestLocation()
        }) {
            if bartViewModel.isLoadingStops {
                HStack {
                    ProgressView()
                    Text("Finding Stops...")
                }
            } else {
                Text("Find Nearby BART Stops")
            }
        }
        .disabled(bartViewModel.isLoadingStops)
        .accessibilityIdentifier("nearbyStopButton")
    }

    @ViewBuilder
    private func stopList(for location: CLLocation) -> some View {
        VStack {
            if let distance = bartViewModel.nearestStopDistance {
                Text("Distance to nearest stop: \(String(format: "%.2f", distance / 1609.34)) miles")
                    
            }
            
            List(bartViewModel.nearbyStops) { stop in
                let station = Station(abbr: stop.bartAbbr ?? "", name: stop.stop_name)
                NavigationLink(destination: TrainListView(station: station, bartManager: bartViewModel.bartManager)) {
                    VStack(alignment: .leading) {
                        Text(stop.stop_name)
                            .font(.headline)
                        Text("ID: \(stop.stop_id)")
                            .font(.subheadline)
                    }
                }
                .accessibilityIdentifier("nearbyStopRow_\(stop.stop_name)")
            }
            .accessibilityIdentifier("nearbyStationList")
        }
    }
    
    private func handleLocationUpdate(_ location: CLLocation?) async {
        print("[CI DEBUG] NearbyStopsView.onReceive: Location received: \(location?.description ?? "nil").")
        guard let location = location else {
            print("[CI DEBUG] NearbyStopsView.onReceive: Location is nil, stopping.")
            bartViewModel.isLoadingStops = false
            return
        }
        print("[CI DEBUG] NearbyStopsView.onReceive: Location is valid, starting findNearbyStops task.")
        await bartViewModel.findNearbyStops(from: location, radius: 1000)
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
        ], mockDistance: 100.0), locationManager: LocationManager())
    }
}
