import Foundation

enum FavoriteType: String, Codable {
    case route
    case station
}

struct FavoriteRoute: Identifiable, Codable, Equatable {
    let id: UUID
    let query: String
    let originStationAbbr: String?
    let destinationStationAbbr: String?
    let type: FavoriteType
    let name: String
    let direction: String?
}
