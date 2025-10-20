import Foundation
import CoreLocation

// Re-using your existing BartETDResponse and related structs
struct BartETDResponse: Decodable {
    let root: BartRoot
}

struct BartRoot: Decodable {
    let station: [BartStation]
}

struct BartStation: Decodable {
    let name: String
    let abbr: String
    let etd: [BartETD]?
}

struct BartETD: Decodable, Identifiable {
    var id: String { destination }
    let destination: String
    let abbreviation: String
    var estimate: [BartEstimate]
}

struct BartEstimate: Decodable, Identifiable {
    var id: String { minutes + (platform ?? "?") + direction } // Ensure unique ID
    let minutes: String
    let platform: String?
    let direction: String
    let length: String?
    let hexcolor: String?
}

// You also provided these models, assuming they are for schedule or other info
struct BartStationScheduleResponse: Decodable {
    let root: BartScheduleRoot
}

struct BartScheduleRoot: Decodable {
    let station: BartScheduleStation
}

struct BartScheduleStation: Decodable {
    let name: String
    let abbr: String
    let item: [BartScheduleItem]
}

struct BartScheduleItem: Decodable, Identifiable { // Added Identifiable
    var id: String { origTime + trainHeadStation }
    let origTime: String
    let trainHeadStation: String
}

// Assuming this Station struct is used for passing station info to the view
struct Station: Decodable, Identifiable, Hashable {
    let id = UUID()
    let abbr: String
    let name: String
    var isFavorite: Bool = false
}

@MainActor
class TrainListViewModel: ObservableObject {
    @Published var etds: [BartETD] = []
    @Published var scheduleItems: [BartScheduleItem] = []
    @Published var nextAvailableTrainTime: String? = nil
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    @Published var direction: String = "" // Made @Published
    private let bartManager: BartManager
    
    init(bartManager: BartManager) {
        self.bartManager = bartManager
    }
    
    // Filtered ETDs based on direction
    var filteredETDs: [BartETD] {
        guard !direction.isEmpty && direction != "All" else { return etds }
        var filtered = [BartETD]()
        for etd in etds {
            let estimates = etd.estimate.filter { estimate in
                print("Estimate direction: \(estimate.direction), Selected direction: \(direction)")
                return estimate.direction.lowercased() == direction.lowercased()
            }
            if !estimates.isEmpty {
                var newETD = etd
                newETD.estimate = estimates
                filtered.append(newETD)
            }
        }
        return filtered
    }
    
    // Placeholder for a BART API key. You MUST replace this with your actual BART API key.
    let apiKey = "MW9S-E7SL-26DU-VV8V"
    
    func fetchETD(for station: Station) async -> [BartETD] {
        isLoading = true
        errorMessage = nil
        etds = []
        scheduleItems = []
        nextAvailableTrainTime = nil
        
        guard let url = URL(string: "https://api.bart.gov/api/etd.aspx?cmd=etd&orig=\(station.abbr)&key=\(apiKey)&json=y") else {
            self.errorMessage = "Invalid URL"
            isLoading = false
            return []
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Raw BART API JSON response: \(jsonString)")
            }
            
            let bartResponse = try JSONDecoder().decode(BartETDResponse.self, from: data)
            
            if let stationData = bartResponse.root.station.first {
                self.etds = stationData.etd ?? []
                
                if self.etds.isEmpty {
                    // If no ETDs, try to fetch schedule
                    await fetchStationSchedule(for: station.abbr)
                }
                isLoading = false
                return self.etds
            } else {
                self.errorMessage = "No station data found in response."
            }
            
        } catch {
            self.errorMessage = "Failed to fetch ETD: \(error.localizedDescription)"
            print("Decoding error: \(error)")
            
            // If ETD fails, try fetching schedule
            await fetchStationSchedule(for: station.abbr)
        }
        isLoading = false
        return []
    }
    
    func fetchStationSchedule(for abbr: String) async {
        guard let url = URL(string: "https://api.bart.gov/api/sched.aspx?cmd=stnsched&orig=\(abbr)&key=\(apiKey)&json=y") else {
            self.errorMessage = "Invalid schedule URL"
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Raw BART Schedule API JSON response: \(jsonString)")
            }
            
            let scheduleResponse = try JSONDecoder().decode(BartStationScheduleResponse.self, from: data)
            
            self.scheduleItems = scheduleResponse.root.station.item
            
            if self.scheduleItems.isEmpty {
                self.nextAvailableTrainTime = "No schedule found for today."
            } else {
                // Find the next available train time from the schedule
                if let firstTrain = self.scheduleItems.first {
                    self.nextAvailableTrainTime = firstTrain.origTime
                }
            }
            
        } catch {
            self.errorMessage = "Failed to fetch schedule: \(error.localizedDescription)"
            print("Decoding schedule error: \(error)")
            self.nextAvailableTrainTime = "Could not fetch schedule."
        }
    }
    
    func printETDs(etds: [BartETD], stationName: String) {
        print("--- ETDs for \(stationName) ---")
        for etd in etds {
            for estimate in etd.estimate {
                print("  - \(etd.destination) train in \(estimate.minutes) minutes (Direction: \(estimate.direction))")
            }
        }
        print("----------------------------------")
    }
    
    func findAndPrintConnectingTrains() async {
        let originStopName = "12th Street / Oakland City Center"
        let destinationStopName = "Embarcadero"

        print("--- Trips through Origin Stop: \(originStopName) ---")
        let originTrips = await bartManager.getTripsPassingThroughStop(stopName: originStopName)
        let groupedOriginTrips = Dictionary(grouping: originTrips, by: { $0["direction_id"] ?? "Unknown" })
        for (direction, trips) in groupedOriginTrips {
            print("  Direction: \(direction)")
            for trip in trips {
                print("    - Headsign: \(trip["trip_headsign"] ?? "N/A")")
            }
        }
        print("----------------------------------")

        print("--- Trips through Destination Stop: \(destinationStopName) ---")
        let destinationTrips = await bartManager.getTripsPassingThroughStop(stopName: destinationStopName)
        let groupedDestinationTrips = Dictionary(grouping: destinationTrips, by: { $0["direction_id"] ?? "Unknown" })
        for (direction, trips) in groupedDestinationTrips {
            print("  Direction: \(direction)")
            for trip in trips {
                print("    - Headsign: \(trip["trip_headsign"] ?? "N/A")")
            }
        }
        print("----------------------------------")

        let connectingTrains = await bartManager.findConnectingTrips(from: originStopName, to: destinationStopName)
        print("--- Connecting Trains (Origin to Destination) ---")
        for train in connectingTrains {
            print("    - Trip ID: \(train.tripId), Headsign: \(train.tripHeadsign), Direction ID: \(train.directionId)")
        }
        print("----------------------------------")
    }
    
    func fetchFilteredETDs(originStation: Station, destinationStation: Station, direction: String) async {
        isLoading = true
        errorMessage = nil
        etds = []
        scheduleItems = []
        nextAvailableTrainTime = nil
        
        // 1. Get connecting trains from GTFS data
        let connectingTrains = await bartManager.findConnectingTrips(from: originStation.name, to: destinationStation.name)
        let allowedDirections = Set(connectingTrains.compactMap { $0.directionId })
        let allowedHeadsigns = Set(connectingTrains.compactMap { $0.tripHeadsign })
        
        // 2. Fetch ETDs for the origin station
        let fetchedETDs = await fetchETD(for: originStation)
        
        // 3. Filter ETDs based on connecting trains and direction
        var finalFilteredETDs: [BartETD] = []
        for etd in fetchedETDs {
            let filteredEstimates = etd.estimate.filter { estimate in
                // Check if the estimate's direction is one of the allowed directions
                // And if the destination of the ETD matches one of the allowed headsigns
                return allowedDirections.contains(estimate.direction) && allowedHeadsigns.contains(etd.destination)
            }
            if !filteredEstimates.isEmpty {
                var newETD = etd
                newETD.estimate = filteredEstimates
                finalFilteredETDs.append(newETD)
            }
        }
        self.etds = finalFilteredETDs
        
        // Handle cases where no ETDs are found after filtering
        if self.etds.isEmpty {
            // If no ETDs, try to fetch schedule (this part might need adjustment based on how schedules are filtered)
            await fetchStationSchedule(for: originStation.abbr)
        }
        isLoading = false
    }
}
