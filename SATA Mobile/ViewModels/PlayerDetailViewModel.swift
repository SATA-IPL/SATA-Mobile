import Foundation

@MainActor
class PlayerDetailViewModel: ObservableObject {
    @Published var playerDetail: PlayerDetail?
    @Published var gameStats: PlayerGameStats?
    @Published var state: ViewState = .loading
    
    func fetchPlayerDetail(id: String) async {
        print("📱 Starting to fetch player detail for ID: \(id)")
        state = .loading
        guard let url = URL(string: "http://144.24.177.214:5000/players/\(id)") else {
            print("❌ Invalid URL for player detail endpoint")
            return
        }
        
        do {
            print("🌐 Fetching player detail from network...")
            let (data, _) = try await URLSession.shared.data(from: url)
            print("✅ Player detail data received: \(data.count) bytes")
            
            // Print received JSON for debugging
            // if let jsonString = String(data: data, encoding: .utf8) {
            //     print("📄 Received JSON: \(jsonString)")
            // }
            
            do {
                playerDetail = try JSONDecoder().decode(PlayerDetail.self, from: data)
                print("📊 Successfully decoded player detail")
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
    
    func fetchPlayerGameStats(gameId: Int, playerId: String) async {
        print("📱 Starting to fetch game stats for Game ID: \(gameId), Player ID: \(playerId)")
        
        guard let url = URL(string: "http://144.24.177.214:5000/game/\(gameId)/statistics/\(playerId)") else {
            print("❌ Invalid URL for player game statistics")
            return
        }
        
        do {
            print("🌐 Fetching game stats from network...")
            let (data, _) = try await URLSession.shared.data(from: url)
            print("✅ Game stats data received: \(data.count) bytes")
            
            // Print received JSON for debugging
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📄 Received JSON: \(jsonString)")
            }
            
            do {
                gameStats = try JSONDecoder().decode(PlayerGameStats.self, from: data)
                print("📊 Successfully decoded game stats")
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
            }
        } catch {
            print("❌ Error fetching game stats: \(error.localizedDescription)")
        }
    }
}
