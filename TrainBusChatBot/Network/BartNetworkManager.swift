
import Foundation

class BartNetworkManager {
    static let shared = BartNetworkManager()
    private let apiKey = "MW9S-E7SL-26DU-VV8V"
    private let session: URLSession

    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        session = URLSession(configuration: configuration)
    }
    
    // Avoids DRY code. Parses json data for each api call
    private func fetch<T: Decodable>(_ type: T.Type, from url: URL) async throws -> T {
        do {
            let (data, _) = try await session.data(from: url)
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            if (error as? URLError)?.code == .cancelled {
                // Handle cancellation gracefully
                throw CancellationError()
            } else {
                throw error
            }
        }
    }

    func fetchETD(for stationAbbr: String) async throws -> [BartETD] {
        let urlString = "https://api.bart.gov/api/etd.aspx?cmd=etd&orig=\(stationAbbr.lowercased())&key=\(apiKey)&json=y"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        let response = try await fetch(BartETDResponse.self, from: url)
        return response.root.station.first?.etd ?? []
    }

    func fetchStationSchedule(for stationAbbr: String) async throws -> [BartScheduleItem] {
        let urlString = "https://api.bart.gov/api/sched.aspx?cmd=stnsched&orig=\(stationAbbr.lowercased())&key=\(apiKey)&json=y"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        let response = try await fetch(BartStationScheduleResponse.self, from: url)
        return response.root.station.item
    }
}
