//
//  TrainListModels.swift
//  TrainBusChatBot
//
//  Created by Carlos on 10/31/25.
//

import Foundation
import SwiftUI

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

struct TrainResult: Identifiable {
    let id = UUID()
    let queryTitle: String      // e.g. "Next Daly City BART to Powell"
    let groups: [TrainGroup]
}

struct TrainGroup: Identifiable {
    let id = UUID()
    let destination: String     // e.g. "Powell"
    let items: [TrainItem]
}

struct TrainItem: Identifiable {
    let id = UUID()
    let minutes: String         // e.g. "4", "Leaving"
    let platform: String
}

struct NearbyStop: Identifiable {
    let id = UUID()
    let name: String
    let distanceMiles: Double
    let walkingMinutes: Int
}
