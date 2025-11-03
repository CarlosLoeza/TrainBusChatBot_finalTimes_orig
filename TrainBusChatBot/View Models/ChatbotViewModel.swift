import Foundation
import CoreLocation

struct Message: Identifiable, Equatable {
    let id = UUID()
    let content: String
    let isUser: Bool
}


@MainActor
class ChatbotViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isLoadingResponse: Bool = false
    @Published var query: String = ""
    @Published var userLocation: CLLocation? // To pass to the chatbotVM
    private let bartManager: BartManager
    private let trainListViewModel: TrainListViewModel
    private let sortedAliases: [String]
    
    init(bartManager: BartManager) {
        self.bartManager = bartManager
        self.trainListViewModel = TrainListViewModel(bartManager: bartManager)
        self.sortedAliases = bartManager.bartAbbreviationMap.keys.sorted { $0.count > $1.count }
        
        // Add initial prompt message
        messages.append(Message(content: "I can help you find nearby BART stops or next train departures. Try asking 'Next Daly City BART' or 'Next Daly City Bart to Powell' if you know your start and destination stop.", isUser: false))
    }
    
    func processQuery(_ query: String, userLocation: CLLocation?) async {
        isLoadingResponse = true
        messages.append(Message(content: query, isUser: true))
        
        let lowercasedQuery = query.lowercased()
        var botResponseContent: String = ""

        if lowercasedQuery.contains("nearby") && lowercasedQuery.contains("bart") {
            botResponseContent = await handleNearbyQuery(userLocation: userLocation)
        } else if lowercasedQuery.contains("next") && lowercasedQuery.contains("bart") && lowercasedQuery.contains("to") {
            botResponseContent = await handleConnectingTrainQuery(query: lowercasedQuery)
        } else if lowercasedQuery.contains("next") && lowercasedQuery.contains("bart") {
            botResponseContent = await handleNextTrainQuery(query: lowercasedQuery)
        } else {
            botResponseContent = handleUnknownQuery()
        }
        
        messages.append(Message(content: botResponseContent, isUser: false))
        isLoadingResponse = false
        self.trainListViewModel.direction = "" // Reset direction after processing
    }

    private func handleNearbyQuery(userLocation: CLLocation?) async -> String {
        guard let userLocation = userLocation else {
            return "I need your location to find nearby BART stops."
        }

        let nearbyStops = await bartManager.findNearbyStops(from: userLocation, radius: 1000)
        if nearbyStops.isEmpty {
            return "No nearby BART stops found."
        } else {
            var responseText = "Nearby BART stops:\n"
            for stop in nearbyStops {
                let stopLocation = CLLocation(latitude: Double(stop.stop_lat) ?? 0, longitude: Double(stop.stop_lon) ?? 0)
                let distanceInMeters = userLocation.distance(from: stopLocation)
                let distanceInMiles = self.metersToMiles(meters: distanceInMeters)
                let walkingTimeInMinutes = self.metersToWalkingMinutes(meters: distanceInMeters)
                
                responseText += "- \(stop.stop_name) (\(String(format: ".2f", distanceInMiles)) miles, approx. \(String(format: ".0f", walkingTimeInMinutes)) min walk)\n"
            }
            return responseText
        }
    }

    private func handleConnectingTrainQuery(query: String) async -> String {
        let extractedDestinationStationName = extractDestinationStationName(from: query)
        let extractedOriginStationName = extractStationName(from: query)

        guard let originStationName = extractedOriginStationName,
              let destinationStationName = extractedDestinationStationName,
              let originStation = findStation(by: originStationName),
              let destinationStation = findStation(by: destinationStationName) else {
            return "Please specify a valid origin and destination, for example: 'next Powell BART to Colma'."
        }

        let connectingTrips = await bartManager.findTripsPassingThrough(originStationName: originStation.name, destinationStationName: destinationStation.name)
        
        if connectingTrips.isEmpty {
            return "No direct trains found from \(originStation.name) to \(destinationStation.name) in the schedule."
        } else {
            let validDestinationAbbrs = Set(connectingTrips.compactMap { trip in
                return self.getAbbr(for: trip.tripHeadsign)
            })

            await trainListViewModel.fetchETD(for: originStation)
            
            if trainListViewModel.etds.isEmpty {
                return "Could not fetch real-time departures for \(originStation.name)."
            } else {
                let filteredETDs = trainListViewModel.etds.filter { etd in
                    let isMatch = validDestinationAbbrs.contains(etd.abbreviation.lowercased())
                    return isMatch
                }
                
                if filteredETDs.isEmpty {
                    return "No real-time trains from \(originStation.name) are heading towards \(destinationStation.name) at the moment."
                } else {
                    var responseText = "Next trains from \(originStation.name) towards \(destinationStation.name):\n"
                    responseText += formatFilteredTrains(filteredETDs, queryDestinationName: destinationStationName)
                    return responseText
                }
            }
        }
    }

    private func handleNextTrainQuery(query: String) async -> String {
        let extractedOriginStationName = extractStationName(from: query)

        guard let originStationName = extractedOriginStationName,
              let originStation = findStation(by: originStationName) else {
            return "I couldn't understand the station name. Please try again."
        }

        let userSpecifiedDirection = extractDirection(from: query)
        self.trainListViewModel.direction = userSpecifiedDirection
            
        await trainListViewModel.fetchETD(for: originStation)
            
        if !trainListViewModel.etds.isEmpty {
            var responseText = "Next trains for \(originStation.name)"
                
            if !userSpecifiedDirection.isEmpty {
                responseText += " going \(userSpecifiedDirection)"
            }
            responseText += ":\n"
                
            let finalFilteredETDs = trainListViewModel.filteredETDs

            if finalFilteredETDs.isEmpty {
                responseText += "No trains found for this direction.\n"
            } else {
                responseText += formatFilteredTrains(finalFilteredETDs, queryDestinationName: nil)
            }
            return responseText
        } else if let nextTime = trainListViewModel.nextAvailableTrainTime {
            return "No real-time trains found for \(originStation.name) going \(userSpecifiedDirection.isEmpty ? "all directions" : userSpecifiedDirection). Next scheduled train at \(nextTime)."
        } else {
            return "No trains found for \(originStation.name) going \(userSpecifiedDirection.isEmpty ? "all directions" : userSpecifiedDirection)."
        }
    }

    private func handleUnknownQuery() -> String {
        return "I can help you find nearby BART stops or next train departures. Try asking 'nearby BART' or 'next Daly City BART going North'."
    }

    private func formatFilteredTrains(_ trains: [BartETD], queryDestinationName: String?) -> String {
        var responseText = ""
        let groupedEstimates = Dictionary(grouping: trains, by: { $0.destination })
        
        for (destination, etdsForDestination) in groupedEstimates {
            responseText += "To \(destination):\n"
            for etd in etdsForDestination {
                for estimate in etd.estimate {
                    responseText += "  - \(estimate.minutes) min (Platform \(estimate.platform ?? "?"))\n"
                }
            }
        }
        return responseText
    }
    
    private func getAbbr(for headsign: String) -> String? {
        // 1. Try for an exact match on the headsign itself
        if let abbr = bartManager.bartAbbreviationMap[headsign] {
            return abbr
        }

        // 2. If no exact match, find the longest alias that is a substring of the headsign.
        for alias in self.sortedAliases { // self.sortedAliases is pre-sorted from longest to shortest
            if headsign.localizedCaseInsensitiveContains(alias) {
                // Return the abbreviation for the matched alias
                return bartManager.bartAbbreviationMap[alias]
            }
        }
        
        print("Warning: Could not find abbreviation for GTFS headsign: '\(headsign)'")
        return nil
    }

    
    
    private func extractStationName(from query: String) -> String? {
        let lowercasedQuery = query.lowercased()

        if let nextRange = lowercasedQuery.range(of: "next "), let bartRange = lowercasedQuery.range(of: " bart") {
            if nextRange.upperBound < bartRange.lowerBound {
                let stationName = String(lowercasedQuery[nextRange.upperBound..<bartRange.lowerBound]).trimmingCharacters(in: .whitespaces)
                for alias in self.sortedAliases {
                    if stationName == alias.lowercased() {
                        return alias
                    }
                }
            }
        }

        var queryToSearch = lowercasedQuery
        if let range = lowercasedQuery.range(of: " to ") {
            queryToSearch = String(lowercasedQuery[..<range.lowerBound])
        } else if let range = lowercasedQuery.range(of: " towards ") {
            queryToSearch = String(lowercasedQuery[..<range.lowerBound])
        }

        for alias in self.sortedAliases {
            if queryToSearch.contains(alias.lowercased()) {
                return alias
            }
        }
        
        return nil
    }
    
    private func extractDestinationStationName(from query: String) -> String? {
        let lowercasedQuery = query.lowercased()
        
        if let range = lowercasedQuery.range(of: " to ") {
            let potentialDestinationQuery = String(lowercasedQuery[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
            
            for alias in self.sortedAliases {
                if potentialDestinationQuery.contains(alias.lowercased()) {
                    return alias
                }
            }
        }
        
        if let range = lowercasedQuery.range(of: " towards ") {
            let potentialDestinationQuery = String(lowercasedQuery[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
            
            for alias in self.sortedAliases {
                if potentialDestinationQuery.contains(alias.lowercased()) {
                    return alias
                }
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
    
    private func findStation(by name: String) -> Station? {
        if let bartAbbr = bartManager.bartAbbreviationMap[name] {
            if let foundStop = bartManager.stops.first(where: { $0.bartAbbr?.lowercased() == bartAbbr.lowercased() }) {
                return Station(abbr: foundStop.bartAbbr ?? "", name: foundStop.stop_name)
            }
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
