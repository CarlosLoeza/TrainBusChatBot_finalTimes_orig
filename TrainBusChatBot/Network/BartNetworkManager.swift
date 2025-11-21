
import Foundation

// Defines custom, user-friendly errors for the network layer.
enum BartAPIError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case noAPIKey
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The server URL is invalid."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError:
            return "Failed to decode the server's response."
        case .noAPIKey:
            return "API Key is missing. Please add it to Secrets.xcconfig."
        }
    }
}

class BartNetworkManager {
    static let shared = BartNetworkManager()
    
    private var apiKey: String {
        #if DEBUG
        return "MW9S-E7SL-26DU-VV8V"
        #else
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "BART_API_KEY") as? String, !apiKey.isEmpty else {
            // This will cause a fatal error in development if the key is missing.
            // In a production app, you might want to handle this more gracefully.
            fatalError("API Key is missing. Add 'BART_API_KEY' to your Secrets.xcconfig file.")
        }
        return apiKey
        #endif
    }
    
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
        } catch let error as DecodingError {
            throw BartAPIError.decodingError(error)
        } catch let error as URLError where error.code == .cancelled {
            throw CancellationError()
        } catch {
            throw BartAPIError.networkError(error)
        }
    }

    func fetchETD(for stationAbbr: String) async throws -> [BartETD] {
        let urlString = "https://api.bart.gov/api/etd.aspx?cmd=etd&orig=\(stationAbbr.lowercased())&key=\(apiKey)&json=y"
        guard let url = URL(string: urlString) else {
            throw BartAPIError.invalidURL
        }
        let response = try await fetch(BartETDResponse.self, from: url)
        return response.root.station.first?.etd ?? []
    }

    func fetchStationSchedule(for stationAbbr: String) async throws -> [BartScheduleItem] {
        let urlString = "https://api.bart.gov/api/sched.aspx?cmd=stnsched&orig=\(stationAbbr.lowercased())&key=\(apiKey)&json=y"
        guard let url = URL(string: urlString) else {
            throw BartAPIError.invalidURL
        }
        let response = try await fetch(BartStationScheduleResponse.self, from: url)
        return response.root.station.item
    }
}
