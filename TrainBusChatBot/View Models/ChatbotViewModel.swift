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
        
        var botResponseContent: String = ""
        
        let lowercasedQuery = query.lowercased()
        let extractedDestinationStationName = extractDestinationStationName(from: query)
        let extractedOriginStationName = extractStationName(from: lowercasedQuery)
        
        if lowercasedQuery.contains("nearby") && lowercasedQuery.contains("bart") {
            if let userLocation = userLocation {
                let nearbyStops = await bartManager.findNearbyStops(from: userLocation, radius: 1000) 
                if nearbyStops.isEmpty {
                    botResponseContent = "No nearby BART stops found."
                } else {
                    var responseText = "Nearby BART stops:\n"
                    for stop in nearbyStops {
                        let stopLocation = CLLocation(latitude: Double(stop.stop_lat) ?? 0, longitude: Double(stop.stop_lon) ?? 0)
                        let distanceInMeters = userLocation.distance(from: stopLocation)
                        let distanceInMiles = self.metersToMiles(meters: distanceInMeters)
                        let walkingTimeInMinutes = self.metersToWalkingMinutes(meters: distanceInMeters)
                        
                        responseText += "- \(stop.stop_name) (\(String(format: ".2f", distanceInMiles)) miles, approx. \(String(format: ".0f", walkingTimeInMinutes)) min walk)\n"
                    }
                    botResponseContent = responseText
                }
            } else {
                botResponseContent = "I need your location to find nearby BART stops."
            }
        } else if lowercasedQuery.contains("next") && lowercasedQuery.contains("bart") && lowercasedQuery.contains("to") {
            print("Attempting to find connecting trips...")
            if let originStationName = extractedOriginStationName,
               let destinationStationName = extractedDestinationStationName,
               let originStation = findStation(by: originStationName),
               let destinationStation = findStation(by: destinationStationName) {
                
                print("Successfully found stations:")
                print("  - Origin: \(originStation.name) (Abbr: \(originStation.abbr))")
                print("  - Destination: \(destinationStation.name) (Abbr: \(destinationStation.abbr))")

                let connectingTrips = await bartManager.findTripsPassingThrough(originStationName: originStation.name, destinationStationName: destinationStation.name)
                
                if connectingTrips.isEmpty {
                    botResponseContent = "No direct trains found from \(originStation.name) to \(destinationStation.name) in the schedule."
                } else {
                    let validDestinationAbbrs = Set(connectingTrips.compactMap { trip in
                        return self.getAbbr(for: trip.tripHeadsign)
                    })
                    print("Valid destination abbreviations from GTFS: \(validDestinationAbbrs)")

                    await trainListViewModel.fetchETD(for: originStation)
                    
                    if trainListViewModel.etds.isEmpty {
                        botResponseContent = "Could not fetch real-time departures for \(originStation.name)."
                    } else {
                        let filteredETDs = trainListViewModel.etds.filter { etd in
                            // Assumes the BartETD struct has a property `abbreviation` for the destination.
                            print("Checking real-time train to \(etd.destination) (Abbr: \(etd.abbreviation))")
                            let isMatch = validDestinationAbbrs.contains(etd.abbreviation.lowercased())
                            print("Result: \(isMatch ? "Match found" : "No match").")
                            return isMatch
                        }
                        
                        if filteredETDs.isEmpty {
                            botResponseContent = "No real-time trains from \(originStation.name) are heading towards \(destinationStation.name) at the moment."
                        } else {
                            var responseText = "Next trains from \(originStation.name) towards \(destinationStation.name):\n"
                            responseText += formatFilteredTrains(filteredETDs, queryDestinationName: destinationStationName)
                            botResponseContent = responseText
                        }
                    }
                }
            } else {
                print("--- Failed to find stations for connecting trip ---")
                if extractedOriginStationName == nil {
                    print("Reason: Origin station name was not extracted.")
                }
                if extractedDestinationStationName == nil {
                    print("Reason: Destination station name was not extracted.")
                }
                if let originName = extractedOriginStationName, findStation(by: originName) == nil {
                    print("Reason: findStation(by: \"\(originName)\") returned nil.")
                }
                if let destName = extractedDestinationStationName, findStation(by: destName) == nil {
                    print("Reason: findStation(by: \"\(destName)\") returned nil.")
                }
                print("----------------------------------------------------")
                botResponseContent = "Please specify a valid origin and destination, for example: 'next Powell BART to Colma'."
            }
        } else if lowercasedQuery.contains("next") && lowercasedQuery.contains("bart") {
            if let originStationName = extractedOriginStationName {
                if let originStation = findStation(by: originStationName) {
                    let userSpecifiedDirection = extractDirection(from: lowercasedQuery)
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
                        botResponseContent = responseText
                    } else if let nextTime = trainListViewModel.nextAvailableTrainTime {
                        botResponseContent = "No real-time trains found for \(originStation.name) going \(userSpecifiedDirection.isEmpty ? "all directions" : userSpecifiedDirection). Next scheduled train at \(nextTime)."
                    } else {
                        botResponseContent = "No trains found for \(originStation.name) going \(userSpecifiedDirection.isEmpty ? "all directions" : userSpecifiedDirection)."
                    }
                }
            }
        } else {
            botResponseContent = "I can help you find nearby BART stops or next train departures. Try asking 'nearby BART' or 'next Daly City BART going North'."
        }
        
        messages.append(Message(content: botResponseContent, isUser: false))
        isLoadingResponse = false
        self.trainListViewModel.direction = "" // Reset direction after processing
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
