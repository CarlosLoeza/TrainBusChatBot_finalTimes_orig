import Foundation

struct FavoriteRoute: Identifiable, Codable, Equatable {
    let id: UUID
    let query: String
    let originStationAbbr: String?
    let destinationStationAbbr: String?
}
