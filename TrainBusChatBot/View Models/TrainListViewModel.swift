import Foundation
import CoreLocation

@MainActor
class TrainListViewModel: ObservableObject {
    @Published var etds: [BartETD] = []
    @Published var scheduleItems: [BartScheduleItem] = []
    @Published var nextAvailableTrainTime: String? = nil
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    @Published var lastUpdatedTime: Date? = nil // Add this line
    @Published var direction: String = "" // Made @Published
    private let bartManager: BartManager
    private var currentFetchTask: Task<Void, Error>? // Add this line

    init(bartManager: BartManager) {
        self.bartManager = bartManager
    }

    var filteredETDs: [BartETD] {
        guard !direction.isEmpty else { return etds } // show all if empty
        return etds.map { etd in
            var filteredETD = etd
            filteredETD.estimate = etd.estimate.filter { $0.direction.lowercased() == direction.lowercased() }
            return filteredETD
        }.filter { !$0.estimate.isEmpty }
    }

    @MainActor
    func fetchETD(for station: Station) async {
        print("[DEBUG] TrainListViewModel: fetchETD called for station: \(station.name)")
        
        // Cancel any existing task
        currentFetchTask?.cancel()
        
        let fetchTask = Task {
            isLoading = true
            errorMessage = nil
            defer { 
                isLoading = false
            }

            // This task can now throw
            let fetchedETDs = try await BartNetworkManager.shared.fetchETD(for: station.abbr)
            self.etds = fetchedETDs
            self.lastUpdatedTime = Date() // Update last updated time on success
            print("✅ Fetch success: \(etds.count) ETDs for station: \(station.name)")
        }
        
        currentFetchTask = fetchTask
        
        do {
            try await fetchTask.value
        } catch is CancellationError {
            print("ℹ️ Fetch for station \(station.name) was cancelled.")
        } catch {
            print("❌ Fetch failed for station \(station.name): \(error.localizedDescription)")
            self.etds = []
            self.errorMessage = (error as? BartAPIError)?.errorDescription ?? "An unknown error occurred."
        }
    }


    func fetchStationSchedule(for abbr: String) async {
        do {
            self.scheduleItems = try await BartNetworkManager.shared.fetchStationSchedule(for: abbr)
        } catch {
            print("❌ Decoding schedule error: \(error.localizedDescription)")
            self.errorMessage = (error as? BartAPIError)?.errorDescription ?? "An unknown error occurred."
        }
    }
    
    /*
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
     */
    
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
        
        // 2. Fetch ETDs for the origin station (this populates self.etds)
        await fetchETD(for: originStation)
        
        // 3. Filter ETDs based on connecting trains and direction
        var finalFilteredETDs: [BartETD] = []
        for etd in self.etds {
            let filteredEstimates = etd.estimate.filter { estimate in
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
            await fetchStationSchedule(for: originStation.abbr)
        }
        
        isLoading = false
    }

}
