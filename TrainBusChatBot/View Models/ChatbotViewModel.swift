import Foundation
import CoreLocation

struct Message: Identifiable, Equatable {
    let id = UUID()
    let content: String
    let isUser: Bool
}

struct ParsedQuery {
    enum Intent {
        case nearby
        case nextTrain
        case connectingTrain
        case unknown
    }
    
    let intent: Intent
    let originStation: Station?
    let destinationStation: Station?
    let direction: String?
}



@MainActor
class ChatbotViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isLoadingResponse: Bool = false
    @Published var query: String = ""
    @Published var userLocation: CLLocation? // To pass to the chatbotVM
    @Published var favoriteRoutes: [FavoriteRoute] = []
    @Published var trainResult: TrainResult? = nil
    @Published var nearbyStops: [NearbyStop] = []
    @Published var message: String = ""

    private let bartManager: BartManager
    private let trainListViewModel: TrainListViewModel
    private let nlpService = NLPService() // New NLP Service
    private let sortedAliases: [String]
    private let userDefaults = UserDefaults.standard
    private let favoriteRoutesKey = "favoriteRoutes"
    private var lastQueryProcessTime: Date?
    private let debounceInterval: TimeInterval = 0.5

    init(bartManager: BartManager) {
        self.bartManager = bartManager
        self.trainListViewModel = TrainListViewModel(bartManager: bartManager)
        self.sortedAliases = bartManager.bartAbbreviationMap.keys.sorted { $0.count > $1.count }
        
        messages.append(Message(content: "I can help you find nearby BART stops or next train departures. Try asking 'Next Daly City BART' or 'Next Daly City Bart to Powell' if you know your start and destination stop.", isUser: false))
        loadFavoriteRoutes()
    }

    // ... (favorite methods remain the same) ...
    private func loadFavoriteRoutes() {
        if let data = userDefaults.data(forKey: favoriteRoutesKey) {
            if let decodedRoutes = try? JSONDecoder().decode([FavoriteRoute].self, from: data) {
                favoriteRoutes = decodedRoutes
            }
        }
    }

    private func saveFavoriteRoutes() {
        if let encodedRoutes = try? JSONEncoder().encode(favoriteRoutes) {
            userDefaults.set(encodedRoutes, forKey: favoriteRoutesKey)
        }
    }

    func toggleFavorite(query: String) {
        if isFavorite(query: query) {
            favoriteRoutes.removeAll { $0.query == query }
        } else {
            let (originStationName, destinationStationName) = extractStationNames(from: query)
            let originStationAbbr = findStation(by: originStationName ?? "")?.abbr
            let destinationStationAbbr = findStation(by: destinationStationName ?? "")?.abbr
            let direction = extractDirection(from: query)

            let type: FavoriteType = (originStationName != nil && destinationStationName != nil) ? .route : .station
            
            let newFavorite = FavoriteRoute(id: UUID(), query: query, originStationAbbr: originStationAbbr, destinationStationAbbr: destinationStationAbbr, type: type, name: query, direction: direction.isEmpty ? nil : direction)
            favoriteRoutes.append(newFavorite)
        }
        saveFavoriteRoutes()
    }

    var routeFavorites: [FavoriteRoute] {
        favoriteRoutes
            .filter{ $0.type == .route }
            .sorted{ $0.name < $1.name}
    }

    var stationFavorites: [FavoriteRoute] {
        favoriteRoutes
            .filter { $0.type == .station }
            .sorted { $0.name < $1.name }
    }

    func isFavorite(query: String) -> Bool {
        return favoriteRoutes.contains { $0.query == query }
    }

    func removeFavorite(at offsets: IndexSet) {
        favoriteRoutes.remove(atOffsets: offsets)
        saveFavoriteRoutes()
    }

    func removeRouteFavorite(at offsets: IndexSet) {
        let favoritesToRemove = offsets.map { routeFavorites[$0] }
        favoriteRoutes.removeAll { favoritesToRemove.contains($0) }
        saveFavoriteRoutes()
    }

    func removeStationFavorite(at offsets: IndexSet) {
        let favoritesToRemove = offsets.map { stationFavorites[$0] }
        favoriteRoutes.removeAll { favoritesToRemove.contains($0) }
        saveFavoriteRoutes()
    }


    // --- NEW processQuery using NLPService ---
    func processQuery(_ query: String, userLocation: CLLocation?) async {
        if let lastTime = lastQueryProcessTime, Date().timeIntervalSince(lastTime) < debounceInterval {
            return
        }
        lastQueryProcessTime = Date()

        isLoadingResponse = true
        messages.append(Message(content: query, isUser: true))

        var botResponseContent: String = ""

        do {
            var parsedIntent = try await nlpService.parseBARTQuery(query)
            
            // --- FIX: Add defensive logic to correct the AI's intent ---
            // If the model incorrectly identifies a connecting train query as a single station query,
            // manually correct the intent before processing.
            if parsedIntent.intent == "next_train", parsedIntent.destination != nil {
                print("Correcting intent from 'next_train' to 'next_connecting_trains' due to presence of a destination.")
                parsedIntent = BARTIntent(intent: "next_connecting_trains", origin: parsedIntent.origin, destination: parsedIntent.destination, time: parsedIntent.time)
            }
            
            switch parsedIntent.intent {
            case "next_train":
                guard let originName = parsedIntent.origin, let originStation = findStation(by: originName) else {
                    botResponseContent = "I couldn't figure out which station you meant. Please be more specific."
                    break
                }
                botResponseContent = await executeNextTrainQuery(station: originStation, direction: "")

            case "next_connecting_trains":
                guard let originName = parsedIntent.origin, let originStation = findStation(by: originName) else {
                    botResponseContent = "I couldn't figure out your starting station. Please be more specific."
                    break
                }
                guard let destName = parsedIntent.destination, let destStation = findStation(by: destName) else {
                    botResponseContent = "I couldn't figure out your destination station. Please be more specific."
                    break
                }
                botResponseContent = await executeConnectingTrainQuery(origin: originStation, destination: destStation)?.formattedString() ?? "No trains found for this route."

            case "nearby_stops":
                botResponseContent = await handleNearbyQuery(userLocation: userLocation)

            default: // "undefined" or any other case
                botResponseContent = handleUnknownQuery()
            }
        } catch {
            botResponseContent = "Sorry, I had trouble understanding that. Please try rephrasing your question. (Error: \(error.localizedDescription))"
            print(botResponseContent)
        }

        messages.append(Message(content: botResponseContent, isUser: false))
        isLoadingResponse = false
        self.trainListViewModel.direction = ""
    }
    
    func executeNextTrainQuery(station: Station, direction: String) async -> String {
        self.trainListViewModel.direction = direction
        await trainListViewModel.fetchETD(for: station)

        let filteredETDs = trainListViewModel.filteredETDs

        if filteredETDs.isEmpty {
            if let nextTime = trainListViewModel.nextAvailableTrainTime {
                return "No real-time trains found for \(station.name) going \(direction.isEmpty ? "all directions" : direction). Next scheduled train at \(nextTime)."
            } else {
                return "No trains found for \(station.name) going \(direction.isEmpty ? "all directions" : direction)."
            }
        }

        let groups = formatFilteredTrains(filteredETDs)
        var responseText = "Next trains for \(station.name)\(direction.isEmpty ? "" : " going \(direction)"):\n"

        for group in groups {
            responseText += "To \(group.destination):\n"
            for item in group.items {
                responseText += "  - \(item.minutes) min (Platform \(item.platform))\n"
            }
        }

        return responseText
    }
    
    func processFavorite(_ favorite: FavoriteRoute) async {
        isLoadingResponse = true
        messages.append(Message(content: favorite.name, isUser: true))

        var botResponseContent: String

        switch favorite.type {
        case .route:
            guard let originAbbr = favorite.originStationAbbr,
                  let destAbbr = favorite.destinationStationAbbr,
                  let originStation = findStation(byAbbr: originAbbr),
                  let destinationStation = findStation(byAbbr: destAbbr) else {
                botResponseContent = "Sorry, there was an error processing this favorite route."
                break
            }
            if let result = await executeConnectingTrainQuery(origin: originStation, destination: destinationStation) {
                botResponseContent = result.formattedString()
            } else {
                botResponseContent = "No trains found for this route."
            }

        case .station:
            guard let originAbbr = favorite.originStationAbbr,
                  let station = findStation(byAbbr: originAbbr) else {
                botResponseContent = "Sorry, there was an error processing this favorite station."
                break
            }
            let direction = favorite.direction ?? ""
            botResponseContent = await executeNextTrainQuery(station: station, direction: direction)
        }

        messages.append(Message(content: botResponseContent, isUser: false))
        isLoadingResponse = false
    }

    func executeConnectingTrainQuery(origin originStation: Station, destination destinationStation: Station) async -> TrainResult? {

        let connectingTrips = await bartManager.findTripsPassingThrough(
            originStationName: originStation.name,
            destinationStationName: destinationStation.name
        )

        if connectingTrips.isEmpty {
            return TrainResult(
                queryTitle: "No direct trains from \(originStation.name) to \(destinationStation.name)",
                groups: []
            )
        }

        let validDestinationAbbrs = Set(
            connectingTrips.compactMap { self.getAbbr(for: $0.tripHeadsign) }
        )

        await trainListViewModel.fetchETD(for: originStation)

        let filteredETDs = trainListViewModel.etds.filter {
            validDestinationAbbrs.contains($0.abbreviation.lowercased())
        }

        let groups = formatFilteredTrains(filteredETDs)

        return TrainResult(
            queryTitle: "Next \(originStation.name) BART to \(destinationStation.name)",
            groups: groups
        )
    }


    func executeNextTrainQueryAsTrainResult(station: Station, direction: String) async -> TrainResult? {
        self.trainListViewModel.direction = direction
        await trainListViewModel.fetchETD(for: station)

        let filteredETDs = trainListViewModel.filteredETDs
        if filteredETDs.isEmpty {
            return nil
        }

        let groups = formatFilteredTrains(filteredETDs)
        return TrainResult(
            queryTitle: "Next trains for \(station.name)\(direction.isEmpty ? "" : " going \(direction)")",
            groups: groups
        )
    }


    private func handleNearbyQuery(userLocation: CLLocation?) async -> String {
        guard let userLocation = userLocation else {
            self.nearbyStops = []
            return "I need your location to find nearby BART stops."
        }

        let stops = await bartManager.findNearbyStops(from: userLocation, radius: 1000)
        if stops.isEmpty {
            self.nearbyStops = []
            return "No nearby BART stops found."
        }

        self.nearbyStops = stops.map { stop in
            let stopLocation = CLLocation(latitude: Double(stop.stop_lat) ?? 0, longitude: Double(stop.stop_lon) ?? 0)
            let distanceInMeters = userLocation.distance(from: stopLocation)
            let distanceInMiles = self.metersToMiles(meters: distanceInMeters)
            let walkingTime = Int(self.metersToWalkingMinutes(meters: distanceInMeters))
            
            return NearbyStop(
                name: stop.stop_name,
                distanceMiles: distanceInMiles,
                walkingMinutes: walkingTime
            )
        }

        return "\(self.nearbyStops.first?.name ?? "") BART is the nearest station to you."
    }



    private func handleConnectingTrainQuery(query: String) async {
        let (originStationName, destinationStationName) = extractStationNames(from: query)

        guard let originName = originStationName,
              let destinationName = destinationStationName,
              let originStation = findStation(by: originName),
              let destinationStation = findStation(by: destinationName) else {
            self.trainResult = nil
            self.message = "Please specify a valid origin and destination, for example: 'next Powell BART to Colma'."
            return
        }

        self.trainResult = await executeConnectingTrainQuery(origin: originStation, destination: destinationStation)
        self.message = ""
    }


    private func handleNextTrainQuery(query: String) async {
        let (originStationName, _) = extractStationNames(from: query)

        guard let originName = originStationName,
              let originStation = findStation(by: originName) else {
            self.trainResult = nil
            self.message = "I couldn't understand the station name. Please try again."
            return
        }

        let userSpecifiedDirection = extractDirection(from: query)
        
        if let nextResult = await executeNextTrainQueryAsTrainResult(station: originStation, direction: userSpecifiedDirection) {
            self.trainResult = nextResult
            self.message = ""
        } else {
            self.trainResult = nil
            self.message = "No trains found for \(originStation.name) going \(userSpecifiedDirection.isEmpty ? "all directions" : userSpecifiedDirection)."
        }
    }


    private func handleUnknownQuery() -> String {
        return "I can help you find nearby BART stops or next train departures. Try asking 'nearby BART' or 'next Daly City BART going North'."
    }

    private func formatFilteredTrains(_ trains: [BartETD]) -> [TrainGroup] {
        let grouped = Dictionary(grouping: trains, by: { $0.destination })
        var groups: [TrainGroup] = []

        for (destination, etds) in grouped {
            var items: [TrainItem] = []

            for etd in etds {
                for estimate in etd.estimate {
                    items.append(
                        TrainItem(
                            minutes: estimate.minutes,
                            platform: estimate.platform ?? "?"
                        )
                    )
                }
            }

            groups.append(TrainGroup(destination: destination, items: items))
        }

        return groups.sorted { $0.destination < $1.destination }
    }
    
    private func getAbbr(for headsign: String) -> String? {
        if let abbr = bartManager.bartAbbreviationMap[headsign] {
            return abbr
        }

        for alias in self.sortedAliases {
            if headsign.localizedCaseInsensitiveContains(alias) {
                return bartManager.bartAbbreviationMap[alias]
            }
        }
        
        print("Warning: Could not find abbreviation for GTFS headsign: '\(headsign)'")
        return nil
    }

    private func extractStationNames(from query: String) -> (origin: String?, destination: String?) {
        let lowercasedQuery = query.lowercased()
        var originPart = lowercasedQuery
        var destinationPart: String?

        let separators = [" to ", " towards "]
        for separator in separators {
            if let range = lowercasedQuery.range(of: separator) {
                originPart = String(lowercasedQuery[..<range.lowerBound])
                destinationPart = String(lowercasedQuery[range.upperBound...])
                break
            }
        }

        let origin = findStationAlias(in: originPart)
        var destination: String?
        if let destPart = destinationPart {
            destination = findStationAlias(in: destPart)
        }

        return (origin, destination)
    }

    private func findStationAlias(in text: String) -> String? {
        if let nextRange = text.range(of: "next "), let bartRange = text.range(of: " bart") {
            if nextRange.upperBound < bartRange.lowerBound {
                let stationName = String(text[nextRange.upperBound..<bartRange.lowerBound]).trimmingCharacters(in: .whitespaces)
                for alias in self.sortedAliases {
                    if stationName == alias.lowercased() {
                        return alias
                    }
                }
            }
        }

        for alias in self.sortedAliases {
            if text.contains(alias.lowercased()) {
                return alias
            }
        }
        return nil
    }
    
    private func extractDirection(from query: String) -> String {
        if query.lowercased().contains("north") {
            return "North"
        } else if query.lowercased().contains("south") {
            return "South"
        } else {
            return ""
        }
    }
    
    // --- UPDATED findStation to be more flexible for LLM output ---
    private func findStation(by name: String) -> Station? {
        let lowercasedName = name.lowercased()
        
        // First, try to find an exact match in the alias map
        if let alias = sortedAliases.first(where: { $0.lowercased() == lowercasedName }) {
            if let bartAbbr = bartManager.bartAbbreviationMap[alias],
               let foundStop = bartManager.stops.first(where: { $0.bartAbbr?.lowercased() == bartAbbr.lowercased() }) {
                return Station(abbr: foundStop.bartAbbr ?? "", name: foundStop.stop_name)
            }
        }
        
        // If no exact match, try to find an alias that is contained in the name
        // (e.g., LLM returns "Powell Street" and alias is "Powell")
        if let alias = sortedAliases.first(where: { lowercasedName.contains($0.lowercased()) }) {
             if let bartAbbr = bartManager.bartAbbreviationMap[alias],
               let foundStop = bartManager.stops.first(where: { $0.bartAbbr?.lowercased() == bartAbbr.lowercased() }) {
                return Station(abbr: foundStop.bartAbbr ?? "", name: foundStop.stop_name)
            }
        }
        
        print("Warning: Could not find station for name: '\(name)'")
        return nil
    }


    private func findStation(byAbbr abbr: String) -> Station? {
        if let foundStop = bartManager.stops.first(where: { $0.bartAbbr?.lowercased() == abbr.lowercased() }) {
            return Station(abbr: foundStop.bartAbbr ?? "", name: foundStop.stop_name)
        }
        return nil
    }

    private func determineTravelDirection(from origin: Station, to destination: Station) -> String? {
        guard let originStop = bartManager.stops.first(where: { $0.bartAbbr == origin.abbr }),
              let destStop = bartManager.stops.first(where: { $0.bartAbbr == destination.abbr }) else {
            return nil
        }

        guard let originLat = Double(originStop.stop_lat),
              let destLat = Double(destStop.stop_lat) else {
            return nil
        }

        if destLat > originLat {
            print("We are going north")
            return "North"
        } else if destLat < originLat {
            print("We are going south")
            return "South"
        } else {
            return nil
        }
    }

    private func getGTFSDirectionId(from origin: Station, to destination: Station) -> String {
        guard let originStop = bartManager.stops.first(where: { $0.bartAbbr == origin.abbr }),
              let destStop = bartManager.stops.first(where: { $0.bartAbbr == destination.abbr }) else {
            return ""
        }

        guard let originLat = Double(originStop.stop_lat),
              let destLat = Double(destStop.stop_lat) else {
            return ""
        }

        if destLat > originLat {
            return "0"
        } else if destLat < originLat {
            return "1"
        } else {
            return ""
        }
    }
    
    private func metersToMiles(meters: CLLocationDistance) -> Double {
        return meters * 0.000621371
    }
    
    private func metersToWalkingMinutes(meters: CLLocationDistance, walkingSpeedMetersPerSecond: Double = 1.34) -> Double {
        return (meters / walkingSpeedMetersPerSecond) / 60
    }
}

extension TrainResult {
    func formattedString() -> String {
        var responseText = "\(queryTitle):\n"
        for group in groups {
            responseText += "To \(group.destination):\n"
            for item in group.items {
                responseText += "  - \(item.minutes) min (Platform \(item.platform))\n"
            }
        }
        return responseText
    }
}

