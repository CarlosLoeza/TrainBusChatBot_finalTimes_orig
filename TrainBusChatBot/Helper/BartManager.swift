import Foundation
import CoreLocation
import CSV

class BartManager {
    
    struct Stop: Codable, Identifiable {
        var id: String { stop_id }
        let stop_id: String
        let stop_code: String
        let stop_name: String
        let stop_lat: String
        let stop_lon: String
        let zone_id: String
        let stop_desc: String
        let stop_url: String
        let location_type: String
        let parent_station: String
        let stop_timezone: String
        let wheelchair_boarding: String
        let platform_code: String
        var bartAbbr: String? // New property for BART abbreviation
    }
    
    struct Route: Codable {
        let route_id: String
        let agency_id: String
        let route_short_name: String
        let route_long_name: String
        let route_desc: String
        let route_type: String
        let route_url: String
        let route_color: String
        let route_text_color: String
    }

    struct ConnectingRouteInfo {
        let route: Route
        let directionId: String
    }
    
    struct Trip: Codable {
        let route_id: String
        let service_id: String
        let trip_id: String
        let trip_headsign: String
        let direction_id: String
        let block_id: String
        let shape_id: String
        let trip_short_name: String
        let wheelchair_accessible: String
        let bikes_allowed: String
    }
    
    struct StopTime: Codable {
        let trip_id: String
        let arrival_time: String
        let departure_time: String
        let stop_id: String
        let stop_sequence: String
        let stop_headsign: String
        let pickup_type: String
        let drop_off_type: String
        let shape_dist_traveled: String
        let timepoint: String
    }
    
    public var stops: [Stop] = []
    public var routes: [Route] = []
    private var trips: [Trip] = []
    private var stopTimes: [StopTime] = []
    
    private var stopNameToIds: [String: Set<String>] = [:]
    private var tripsById: [String: Trip] = [:]
    private var routeById: [String: Route] = [:]
    private var stopTimesByTripId: [String: [StopTime]] = [:]
    private var routesByStopId: [String: Set<String>] = [:]

    
    // Mapping from station alias to BART abbreviation
    public let bartAbbreviationMap: [String: String] = [
        "12th Street / Oakland City Center": "12th",
        "12th St": "12th",
        "12th": "12th",
        "16th Street / Mission": "16th",
        "16th St": "16th",
        "16th": "16th",
        "19th Street Oakland": "19th",
        "19th St": "19th",
        "19th": "19th",
        "24th Street / Mission": "24th",
        "24th St": "24th",
        "24th": "24th",
        "Antioch": "antc",
        "Ashby": "ashb",
        "Balboa Park": "balb",
        "Balboa": "balb",
        "Bay Fair": "bayf",
        "Berryessa / North San Jose": "bery",
        "Berryessa": "bery",
        "Castro Valley": "cast",
        "Castro": "cast",
        "Civic Center / UN Plaza": "civc",
        "Civic Center": "civc",
        "Coliseum": "cols",
        "Colma": "colm",
        "Concord": "conc",
        "Daly City": "daly",
        "Daly": "daly",
        "Downtown Berkeley": "dbrk",
        "Downtown": "dbrk",
        "Dublin / Pleasanton": "dubl",
        "Dublin": "dubl",
        "El Cerrito Del Norte": "deln",
        "El Cerrito North": "deln",
        "El Cerrito Plaza": "plza",
        "Embarcadero": "embr",
        "Fremont": "frmt",
        "Fruitvale": "ftvl",
        "Glen Park": "glen",
        "Glen": "glen",
        "Hayward": "hayw",
        "Lafayette": "lafy",
        "Lake Merritt": "lake",
        "MacArthur": "mcar",
        "Millbrae": "mlbr",
        "Millbrae (Caltrain Transfer Platform)": "mlbr",
        "Milpitas": "mlpt",
        "Montgomery Street": "mont",
        "Montgomery St": "mont",
        "Montgomery": "mont",
        "North Berkeley": "nbrk",
        "North Concord / Martinez": "ncon",
        "North Concord": "ncon",
        "Oakland International Airport": "oakl",
        "Oakland Airport": "oakl",
        "Orinda": "orin",
        "Pittsburg / Bay Point": "pitt",
        "Pittsburg Bay Point": "pitt",
        "Pittsburg Center": "pctr",
        "Pittsburg": "pctr",
        "Pleasant Hill / Contra Costa Centre": "phil",
        "Pleasant Hill": "phil",
        "Powell Street": "powl",
        "Powell St": "powl",
        "Powell": "powl",
        "Richmond": "rich",
        "Rockridge": "rock",
        "San Bruno": "sbrn",
        "San Francisco International Airport": "sfia",
        "SFO": "sfia",
        "San Leandro": "sanl",
        "South Hayward": "shay",
        "South San Francisco": "ssan",
        "Union City": "ucty",
        "Walnut Creek": "wcrk",
        "Warm Springs / South Fremont": "warm",
        "Warm Springs": "warm",
        "West Dublin / Pleasanton": "wdub",
        "West Dublin": "wdub",
        "West Oakland": "woak"
    ]
    
    // Main initializer for actual app use
    init() async {
        print("BartManager init")
        await loadGTFSData()
    }
    
    // Initializer for previews or synchronous use
    init(isPreview: Bool = false) {
        if isPreview {
            // Do not load real data for previews
            self.stops = []
        }
    }
    
    private func loadGTFSData() async {
        print("loadGTFSData called")
        await loadStops()
        await loadRoutes()
        await loadTrips()
        await loadStopTimes()
        
        // Build all maps for fast lookups
        buildStopNameToIdsMap()
        buildTripsByIdMap()
        buildRouteByIdMap()
        buildStopTimesByTripIdMap()
        buildRoutesByStopIdMap()
        printStationRouteInfo()

        print("GTFS Data and indexes loaded.")
    }
    
    private func buildStopNameToIdsMap() {
        print("Building stop name to IDs map...")
        var map: [String: Set<String>] = [:]
        for stop in stops {
            let name = stop.stop_name.lowercased()
            map[name, default: Set<String>()].insert(stop.stop_id)
        }
        self.stopNameToIds = map
        print("Stop name to IDs map built. Contains \(map.count) entries.")
    }
    
    private func buildTripsByIdMap() {
        print("Building trips by ID map...")
        self.tripsById = Dictionary(uniqueKeysWithValues: trips.map { ($0.trip_id, $0) })
        print("Trips by ID map built. Contains \(tripsById.count) entries.")
    }

    private func buildRouteByIdMap() {
        print("Building route by ID map...")
        self.routeById = Dictionary(uniqueKeysWithValues: routes.map { ($0.route_id, $0) })
        print("Route by ID map built. Contains \(routeById.count) entries.")
    }

    private func buildStopTimesByTripIdMap() {
        print("Building stop times by trip ID map...")
        var map = Dictionary(grouping: self.stopTimes, by: { $0.trip_id })

        for (tripId, stopTimes) in map {
            map[tripId] = stopTimes.sorted { (st1, st2) -> Bool in
                guard let seq1 = Int(st1.stop_sequence), let seq2 = Int(st2.stop_sequence) else { return false }
                return seq1 < seq2
            }
        }
        
        self.stopTimesByTripId = map
        print("Stop times by trip ID map built. Contains \(map.count) entries.")
    }

    private func buildRoutesByStopIdMap() {
        print("Building routes by stop ID map...")
        var map: [String: Set<String>] = [:]
        for stopTime in stopTimes {
            if let trip = tripsById[stopTime.trip_id] {
                map[stopTime.stop_id, default: Set<String>()].insert(trip.route_id)
            }
        }
        self.routesByStopId = map
        print("Routes by stop ID map built. Contains \(map.count) entries.")
    }

    
    private func loadStops() async {
        print("loadStops called")
        let stopIds = await loadStopIdsFromStopTimes()
        print("Number of stopIds from stop_times: \(stopIds.count)")
        
        await Task.detached { @MainActor in
            if let url = Bundle.main.url(forResource: "stops", withExtension: "txt") {
                do {
                    let csv = try CSVReader(stream: InputStream(url: url)!)
                    var allStops: [Stop] = []
                    _ = csv.next() // Skip header
                    while let row = csv.next() {
                        if row.count == 13 {
                            var stop = Stop(stop_id: row[0], stop_code: row[1], stop_name: row[2], stop_lat: row[3], stop_lon: row[4], zone_id: row[5], stop_desc: row[6], stop_url: row[7], location_type: row[8], parent_station: row[9], stop_timezone: row[10], wheelchair_boarding: row[11], platform_code: row[12])
                        stop.bartAbbr = self.bartAbbreviationMap[stop.stop_name]
                            allStops.append(stop)
                        }
                    }
                    self.stops = allStops.filter { stopIds.contains($0.stop_id) }
                } catch {
                    print("Error initializing CSVReader for stops.txt: \(error)")
                }
            } else {
                print("stops.txt File URL not found")
            }
        }.value
    }
    
    private func loadRoutes() async {
        await Task.detached { @MainActor in
            if let url = Bundle.main.url(forResource: "routes", withExtension: "txt") {
                do {
                    let csv = try CSVReader(stream: InputStream(url: url)!)
                    _ = csv.next() // Skip header
                    var loadedRoutes: [Route] = []
                    while let row = csv.next() {
                        if row.count == 9 {
                            let route = Route(route_id: row[0], agency_id: row[1], route_short_name: row[2], route_long_name: row[3], route_desc: row[4], route_type: row[5], route_url: row[6], route_color: row[7], route_text_color: row[8])
                            loadedRoutes.append(route)
                        }
                    }
                    self.routes = loadedRoutes
                } catch {
                    print("Error loading routes.txt: \(error)")
                }
            }
        }.value
    }
    
    private func loadTrips() async {
        await Task.detached { @MainActor in
            if let url = Bundle.main.url(forResource: "trips", withExtension: "txt") {
                do {
                    let csv = try CSVReader(stream: InputStream(url: url)!)
                     _ = csv.next() // Skip header
                    var loadedTrips: [Trip] = []
                    while let row = csv.next() {
                        if row.count == 10 {
                            let trip = Trip(route_id: row[0], service_id: row[1], trip_id: row[2], trip_headsign: row[3], direction_id: row[4], block_id: row[5], shape_id: row[6], trip_short_name: row[7], wheelchair_accessible: row[8], bikes_allowed: row[9])
                            loadedTrips.append(trip)
                        }
                    }
                    self.trips = loadedTrips
                } catch {
                    print("Error loading trips.txt: \(error)")
                }
            }
        }.value
    }
    
    private func loadStopTimes() async {
        await Task.detached { @MainActor in
            if let url = Bundle.main.url(forResource: "stop_times", withExtension: "txt") {
                do {
                    let csv = try CSVReader(stream: InputStream(url: url)!)
                    _ = csv.next() // Skip header
                    var loadedStopTimes: [StopTime] = []
                    while let row = csv.next() {
                        if row.count == 10 {
                            let stopTime = StopTime(trip_id: row[0], arrival_time: row[1], departure_time: row[2], stop_id: row[3], stop_sequence: row[4], stop_headsign: row[5], pickup_type: row[6], drop_off_type: row[7], shape_dist_traveled: row[8], timepoint: row[9])
                            loadedStopTimes.append(stopTime)
                        }
                    }
                    self.stopTimes = loadedStopTimes
                } catch {
                    print("Error loading stop_times.txt: \(error)")
                }
            }
        }.value
    }
    
    private func loadStopIdsFromStopTimes() async -> Set<String> {
        var stopIds = Set<String>()
        if let url = Bundle.main.url(forResource: "stop_times", withExtension: "txt") {
            do {
                let csv = try CSVReader(stream: InputStream(url: url)!)
                _ = csv.next() // Skip header
                while let row = csv.next() {
                    if row.count > 3 {
                        stopIds.insert(row[3])
                    }
                }
            } catch {
                print("Error loading stop_times: \(error)")
            }
        }
        return stopIds
    }
    
    func findNearbyStops(from location: CLLocation, radius: CLLocationDistance) async -> [Stop] {
        let nearbyStops = stops.filter { stop in
            let stopLocation = CLLocation(latitude: Double(stop.stop_lat) ?? 0, longitude: Double(stop.stop_lon) ?? 0)
            let distance = location.distance(from: stopLocation)
            return distance <= radius
        }
        
        var uniqueStops: [Stop] = []
        var uniqueStopNames = Set<String>()
        for stop in nearbyStops {
            if !uniqueStopNames.contains(stop.stop_name) {
                uniqueStops.append(stop)
                uniqueStopNames.insert(stop.stop_name)
            }
        }
        
        let sortedStops = uniqueStops.sorted { (stop1, stop2) -> Bool in
            let location1 = CLLocation(latitude: Double(stop1.stop_lat) ?? 0, longitude: Double(stop1.stop_lon) ?? 0)
            let location2 = CLLocation(latitude: Double(stop2.stop_lat) ?? 0, longitude: Double(stop2.stop_lon) ?? 0)
            return location.distance(from: location1) < location.distance(from: location2)
        }
        return sortedStops
    }
    
    struct ConnectingTripInfo {
        let tripId: String
        let tripHeadsign: String
        let directionId: String
    }

    func findConnectingTrips(from originStationName: String, to destinationStationName: String) async -> [ConnectingTripInfo] {
        print("--- Finding Connecting Trips (Optimized) from \(originStationName) to \(destinationStationName) ---")

        guard let originStopIds = stopNameToIds[originStationName.lowercased()] else {
            print("Error: Could not find stop IDs for origin station: \(originStationName)")
            return []
        }

        guard let destinationStopIds = stopNameToIds[destinationStationName.lowercased()] else {
            print("Error: Could not find stop IDs for destination station: \(destinationStationName)")
            return []
        }

        let tripsThroughOrigin = stopTimes.filter { originStopIds.contains($0.stop_id) }
        let tripsThroughDestination = stopTimes.filter { destinationStopIds.contains($0.stop_id) }

        let originTripIds = Set(tripsThroughOrigin.map { $0.trip_id })
        let destinationTripIds = Set(tripsThroughDestination.map { $0.trip_id })

        let commonTripIds = originTripIds.intersection(destinationTripIds)
        print("Found \(commonTripIds.count) common trips.")

        var connectingTrips: [ConnectingTripInfo] = []

        for tripId in commonTripIds {
            guard let trip = tripsById[tripId] else {
                continue
            }

            guard let stopTimesForTrip = stopTimesByTripId[tripId] else {
                continue
            }

            guard let originStopTime = stopTimesForTrip.first(where: { originStopIds.contains($0.stop_id) }),
                  let destinationStopTime = stopTimesForTrip.first(where: { destinationStopIds.contains($0.stop_id) }) else {
                continue
            }
            
            guard let originSequence = Int(originStopTime.stop_sequence),
                  let destinationSequence = Int(destinationStopTime.stop_sequence),
                  destinationSequence > originSequence else {
                continue
            }
            
            print("Found connecting trip: \(trip.trip_headsign) via trip \(tripId)")
            let connectingTrip = ConnectingTripInfo(tripId: trip.trip_id, tripHeadsign: trip.trip_headsign, directionId: trip.direction_id)
            connectingTrips.append(connectingTrip)
        }
        
        print("Found \(connectingTrips.count) total connecting trip possibilities.")
        return connectingTrips
    }

    func getTripsPassingThroughStop(stopName: String) async -> [[String: String]] {
        print("--- Getting trips passing through \(stopName) ---")
        var tripsAtStop: [[String: String]] = []

        guard let stopIds = stopNameToIds[stopName.lowercased()] else {
            print("Error: Could not find stop IDs for station: \(stopName)")
            return []
        }
        print("Found \(stopIds.count) stop IDs for station \(stopName): \(stopIds)")

        var uniqueRouteIdsForStop: Set<String> = []
        for stopId in stopIds {
            if let routeIds = routesByStopId[stopId] {
                uniqueRouteIdsForStop.formUnion(routeIds)
            }
        }
        print("Found \(uniqueRouteIdsForStop.count) unique route IDs for the station.")

        var uniqueTripInfos: Set<String> = [] // To store unique trip_headsign + direction_id combinations
        for routeId in uniqueRouteIdsForStop {
            // Find all trips for this route
            let tripsForRoute = trips.filter { $0.route_id == routeId }
            for trip in tripsForRoute {
                // Check if this trip actually passes through one of the stopIds
                // This is important because a route might have many trips, but not all trips stop at every station on the route.
                if let stopTimesForTrip = stopTimesByTripId[trip.trip_id],
                   stopTimesForTrip.contains(where: { stopIds.contains($0.stop_id) }) {

                    let tripIdentifier = "\(trip.trip_headsign)-\(trip.direction_id)"
                    if !uniqueTripInfos.contains(tripIdentifier) {
                        let tripInfo = [
                            "trip_headsign": trip.trip_headsign,
                            "direction_id": trip.direction_id
                        ]
                        tripsAtStop.append(tripInfo)
                        uniqueTripInfos.insert(tripIdentifier)
                    }
                }
            }
        }
        print("Found \(tripsAtStop.count) trips with headsigns.")
        return tripsAtStop
    }

    func getStopsOnTripAfter(tripId: String, afterStopId: String) -> [String] {
        var subsequentStopNames: [String] = []

        guard let stopTimesForTrip = stopTimesByTripId[tripId], let originStopTime = stopTimesForTrip.first(where: { $0.stop_id == afterStopId }), let originSequence = Int(originStopTime.stop_sequence) else {
            return []
        }

        for stopTime in stopTimesForTrip {
            guard let currentSequence = Int(stopTime.stop_sequence) else { continue }
            if currentSequence > originSequence {
                if let stop = stops.first(where: { $0.stop_id == stopTime.stop_id }) {
                    subsequentStopNames.append(stop.stop_name)
                }
            }
        }
        return subsequentStopNames
    }

    public func printAllBartRoutes() {
        print("--- BART Routes ---")
        for route in routes {
            print("Route ID: \(route.route_id)")
            print("  Short Name: \(route.route_short_name)")
            print("  Long Name: \(route.route_long_name)")
            print("  Description: \(route.route_desc)")

            let tripsForRoute = trips.filter { $0.route_id == route.route_id }
            let uniqueDirections = Set(tripsForRoute.map { $0.direction_id }).sorted()

            if !uniqueDirections.isEmpty {
                print("  Directions: \(uniqueDirections.joined(separator: ", "))")
                
                for directionId in uniqueDirections.sorted() {
                    print("    Direction \(directionId):")
                    if let representativeTrip = tripsForRoute.first(where: { $0.direction_id == directionId }), let stopTimesForTrip = stopTimesByTripId[representativeTrip.trip_id] {
                        var stopNamesForDirection: [String] = []
                        for stopTime in stopTimesForTrip {
                            if let stop = stops.first(where: { $0.stop_id == stopTime.stop_id }) {
                                stopNamesForDirection.append(stop.stop_name)
                            }
                        }
                        print("      Stops: \(stopNamesForDirection.joined(separator: " -> "))")
                    } else {
                        print("      No trips found for this direction.")
                    }
                }
            } else {
                print("  Directions: N/A")
            }
            print("--------------------")
        }
    }

    public func findConnectingRoutes(from originStationName: String, to destinationStationName: String, direction: String) -> [ConnectingRouteInfo] {
        print("--- Finding Connecting Routes (Optimized) from \(originStationName) to \(destinationStationName) (Direction: \(direction)) ---")

        guard let originStopIds = stopNameToIds[originStationName.lowercased()] else {
            print("Error: Could not find stop IDs for origin station: \(originStationName)")
            return []
        }
        print("Found \(originStopIds.count) stop IDs for origin station \(originStationName): \(originStopIds)")

        guard let destinationStopIds = stopNameToIds[destinationStationName.lowercased()] else {
            print("Error: Could not find stop IDs for destination station: \(destinationStationName)")
            return []
        }
        print("Found \(destinationStopIds.count) stop IDs for destination station \(destinationStationName): \(destinationStopIds)")

        let tripsThroughOrigin = stopTimes.filter { originStopIds.contains($0.stop_id) }
        print("Found \(tripsThroughOrigin.count) stop times through origin station.")
        
        let tripsThroughDestination = stopTimes.filter { destinationStopIds.contains($0.stop_id) }
        print("Found \(tripsThroughDestination.count) stop times through destination station.")

        let originTripIds = Set(tripsThroughOrigin.map { $0.trip_id })
        let destinationTripIds = Set(tripsThroughDestination.map { $0.trip_id })

        let commonTripIds = originTripIds.intersection(destinationTripIds)
        print("Found \(commonTripIds.count) common trips.")

        var connectingRoutes: [ConnectingRouteInfo] = []
        var processedRouteIds: Set<String> = []

        for tripId in commonTripIds {
            guard let trip = tripsById[tripId], trip.direction_id == direction else {
                continue
            }

            guard let stopTimesForTrip = stopTimesByTripId[tripId] else {
                continue
            }

            guard let originStopTime = stopTimesForTrip.first(where: { originStopIds.contains($0.stop_id) }),
                  let destinationStopTime = stopTimesForTrip.first(where: { destinationStopIds.contains($0.stop_id) }) else {
                continue
            }
            
            guard let originSequence = Int(originStopTime.stop_sequence),
                  let destinationSequence = Int(destinationStopTime.stop_sequence),
                  destinationSequence > originSequence else {
                continue
            }

            if !processedRouteIds.contains(trip.route_id) {
                if let route = routeById[trip.route_id] {
                    print("Found connecting route: \(route.route_long_name) via trip \(tripId)")
                    connectingRoutes.append(ConnectingRouteInfo(route: route, directionId: direction))
                    processedRouteIds.insert(trip.route_id)
                }
            }
        }

        if connectingRoutes.isEmpty {
            print("No connecting routes found for the specified stations and direction.")
        } else {
            print("Found \(connectingRoutes.count) connecting routes:")
            for routeInfo in connectingRoutes {
                print("  - \(routeInfo.route.route_long_name) (Route ID: \(routeInfo.route.route_id))")
            }
        }
        print("------------------------------------------------------------------")
        return connectingRoutes
    }

    public func printStationRouteInfo() {
        print("--- Station Route Information ---")
        var processedStationNames: Set<String> = []
        for stop in stops.sorted(by: { $0.stop_name < $1.stop_name }) {
            if processedStationNames.contains(stop.stop_name) {
                continue
            }
            processedStationNames.insert(stop.stop_name)

            var uniqueRoutesForStation: Set<String> = []
            let stopIdsForThisName = stops.filter { $0.stop_name == stop.stop_name }.map { $0.stop_id }

            for stopId in stopIdsForThisName {
                if let routeIds = routesByStopId[stopId] {
                    for routeId in routeIds {
                        if let route = routeById[routeId] {
                            uniqueRoutesForStation.insert(route.route_long_name)
                        }
                    }
                }
            }

            if !uniqueRoutesForStation.isEmpty {
                print("Station: \(stop.stop_name)")
                print("  Routes: \(uniqueRoutesForStation.sorted().joined(separator: ", "))")
            } else {
                print("Station: \(stop.stop_name)")
                print("  No routes found for this station.")
            }
        }
        print("---------------------------------")
    }
}