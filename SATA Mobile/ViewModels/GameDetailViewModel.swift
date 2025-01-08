import Foundation
import GoogleGenerativeAI
import SwiftUI

@MainActor
class GameDetailViewModel: ObservableObject {
    @Published var game: Game?
    @Published var state: ViewState = .loading
    @Published var isLoading = false
    @Published var response: LocalizedStringKey = "How can I help you today?"
    @Published var events: [Event] = []
    @Published var homeStatistics: [Statistics] = []
    @Published var awayStatistics: [Statistics] = []
    
    private static let config = GenerationConfig(
        temperature: 1,
        topP: 0.95,
        topK: 40,
        maxOutputTokens: 8192,
        responseMIMEType: "text/plain"
    )
    
    lazy var model: GenerativeModel = {
        GenerativeModel(
            name: "gemini-2.0-flash-exp",
            apiKey: APIKey.default,
            generationConfig: GameDetailViewModel.config
        )
    }()
    
    func fetchGameDetail(id: Int) async {
        print("📱 Starting to fetch game details for ID: \(id)")
        state = .loading
        
        guard let url = URL(string: "http://144.24.177.214:5000/games/\(id)") else {
            print("❌ Invalid URL for game detail endpoint")
            return
        }
        
        do {
            print("🌐 Fetching game details from network...")
            let (data, _) = try await URLSession.shared.data(from: url)
            print("✅ Game detail data received: \(data.count) bytes")
            
            // Print received JSON for debugging
             if let jsonString = String(data: data, encoding: .utf8) {
                 print("📄 Received JSON: \(jsonString)")
             }
            
            do {
                game = try JSONDecoder().decode(Game.self, from: data)
                print("📊 Successfully decoded game details")
                state = .loaded
            } catch let decodingError as DecodingError {
                switch decodingError {
                case .typeMismatch(let type, let context):
                    print("❌ Type mismatch: expected \(type) at path: \(context.codingPath)")
                case .valueNotFound(let type, let context):
                    print("❌ Value missing: expected \(type) at path: \(context.codingPath)")
                case .keyNotFound(let key, let context):
                    print("❌ Key missing: \(key) at path: \(context.codingPath)")
                case .dataCorrupted(let context):
                    print("❌ Data corrupted: \(context.debugDescription)")
                @unknown default:
                    print("❌ Unknown decoding error: \(decodingError)")
                }
                state = .error("JSON Decoding Error: \(decodingError.localizedDescription)")
            }
        } catch {
            print("❌ Network error: \(error.localizedDescription)")
            state = .error(error.localizedDescription)
        }
    }
    
    func generateResponse(userPrompt: String) async {
        isLoading = true
        response = ""
        
        do {
            let result = try await model.generateContent(userPrompt)
            isLoading = false
            response = LocalizedStringKey(result.text ?? "No response found")
        } catch {
            response = "Something went wrong! \n\(error.localizedDescription)"
            isLoading = false
        }
    }
    
    func fetchEvents(gameId: Int) async {
            print("📱 Starting to fetch events for game ID: \(gameId)")
            
            guard let url = URL(string: "http://144.24.177.214:5000/events/\(gameId)") else {
                print("❌ Invalid URL for events endpoint")
                return
            }
            
            do {
                print("🌐 Fetching events from network...")
                let (data, _) = try await URLSession.shared.data(from: url)
                print("✅ Events data received: \(data.count) bytes")
                
                // Print received JSON for debugging
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("📄 Received JSON: \(jsonString)")
                }
                
                events = try JSONDecoder().decode([Event].self, from: data)
                print("📊 Successfully decoded \(events.count) events")
            } catch {
                print("❌ Error fetching events: \(error)")
            }
        }
    func fetchHomeStatistics(gameId: Int) async {
        print("📱 Starting to fetch events for game ID: \(gameId)")
        
        guard let url = URL(string: "http://144.24.177.214:5000/game/\(gameId)/statistics/home") else {
            print("❌ Invalid URL for home statistics endpoint")
            return
        }
        
        do {
            print("🌐 Fetching home statistics from network...")
            let (data, _) = try await URLSession.shared.data(from: url)
            print("✅ Home Statistics data received: \(data.count) bytes")
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📄 Received JSON: \(jsonString)")
            }
            
            let stat = try JSONDecoder().decode(Statistics.self, from: data)
            homeStatistics = [stat]
            print("📊 Successfully decoded home statistics")
            
        } catch {
            print("❌ Error fetching home stats: \(error)")
        }
    }

    func fetchAwayStatistics(gameId: Int) async {
        print("📱 Starting to fetch away statistics for game ID: \(gameId)")
        
        guard let url = URL(string: "http://144.24.177.214:5000/game/\(gameId)/statistics/away") else {
            print("❌ Invalid URL for events endpoint")
            return
        }
        
        do {
            print("🌐 Fetching away statistics from network...")
            let (data, _) = try await URLSession.shared.data(from: url)
            print("✅ Away Statistics data received: \(data.count) bytes")
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📄 Received JSON: \(jsonString)")
            }
            
            let stat = try JSONDecoder().decode(Statistics.self, from: data)
            awayStatistics = [stat]
            print("📊 Successfully decoded away statistics")
        } catch {
            print("❌ Error fetching away stats: \(error)")
        }
    }
}

