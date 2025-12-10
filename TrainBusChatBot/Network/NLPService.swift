import Foundation

// MARK: - Models

struct BARTIntent: Codable {
    let intent: String
    let origin: String?
    let destination: String?
    let time: String?
}

struct ChatMessage: Codable {
    let role: String
    let content: String
}

struct ChatRequest: Codable {
    let model: String
    let messages: [ChatMessage]
    let max_tokens: Int
}

struct ChatResponse: Codable {
    struct Choice: Codable {
        struct Message: Codable {
            let role: String
            let content: String
        }
        let message: Message
    }
    let choices: [Choice]
}


// MARK: - NLP Service

class NLPService {
    private let endpoint = "https://router.huggingface.co/v1/chat/completions"
    // IMPORTANT: Replace with your actual Hugging Face token.
    // It is recommended to load this from a secure location (e.g., Secrets.xcconfig)
    // rather than hardcoding it.
    private var apiKey: String? {
        // Read the API key from the Info.plist, which is populated by Secrets.xcconfig
        return Bundle.main.object(forInfoDictionaryKey: "HUGGING_FACE_API_KEY") as? String
    }

    func parseBARTQuery(_ query: String) async throws -> BARTIntent {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            throw NSError(domain: "NLPService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Hugging Face API key is missing."])
        }
        
        guard let url = URL(string: endpoint) else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        // System prompt to enforce JSON structured output
        let systemMessage = ChatMessage(
            role: "system",
            content: """
                    You are an NLP engine for a BART transit app. Your job is ONLY to return structured JSON, never explanations or natural language. ALWAYS output exactly ONE JSON object.

                    Format:
                    {
                      "intent": "string",
                      "origin": "string" or null,
                      "destination": "string" or null,
                      "time": "string" or null
                    }

                    Supported intents: "next_train", "next_connecting_trains", "nearby_stops", "undefined".

                    Rules:
                    - If the user asks about the next train at a single station, set intent = "next_train".
                    - If the user asks about the next train from one station to another, set intent = "next_connecting_trains".
                    - If the user asks for nearby stops, use "nearby_stops".
                    - Extract station names exactly as written by the user.
                    - NEVER guess stations. Only extract what the user typed.
                    - ALWAYS return valid JSON only.

                    Direction Interpretation Rules:
                    - Phrases like "to X", "towards X", "toward X", "headed to X", "going to X", "in the direction of X" indicate DESTINATION = X.
                    - If the user says “A headed to B”, then origin = A and destination = B.
                    - If the user says “A going in the direction of B”, then origin = A and destination = B.
                    - If the user says “train to B” but does NOT specify origin, then origin = null and destination = B.
                    - If the user mentions only one station with no direction (“Next Daly City bart”), origin = Daly City.
                    - If the user mentions no stations, set both origin and destination to null.


                    """
        )

        let userMessage = ChatMessage(role: "user", content: query)

        let chatRequest = ChatRequest(
            model: "meta-llama/Llama-3.1-8B-Instruct",
            messages: [systemMessage, userMessage],
            max_tokens: 150
        )

        request.httpBody = try JSONEncoder().encode(chatRequest)

        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            let errorBody = String(data: data, encoding: .utf8) ?? "No error body"
            throw NSError(domain: "NLPService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "API Error: \(errorBody)"])
        }


        // Decode the HF chat response
        let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)
        print("chatResponse: \(chatResponse)")
        guard let content = chatResponse.choices.first?.message.content else {
            throw NSError(domain: "NLPService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Empty HF response"])
        }

        // The model might return the JSON inside a markdown block, so we need to extract it.
        let jsonString = content.trimmingCharacters(in: .whitespacesAndNewlines)
                                .replacingOccurrences(of: "```json", with: "")
                                .replacingOccurrences(of: "```", with: "")
                                .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let jsonData = jsonString.data(using: .utf8) else {
            throw NSError(domain: "NLPService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON string from model: \(content)"])
        }

        do {
            let bartIntent = try JSONDecoder().decode(BARTIntent.self, from: jsonData)
            return bartIntent
        } catch {
            throw NSError(domain: "NLPService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to decode BARTIntent from model response: \(jsonString). Error: \(error)"])
        }
    }
}
