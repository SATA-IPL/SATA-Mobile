import Foundation

@MainActor
class GameDetailViewModel: ObservableObject {
    @Published var game: Game?
    @Published var state: ViewState = .loading
    
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
            // if let jsonString = String(data: data, encoding: .utf8) {
            //     print("📄 Received JSON: \(jsonString)")
            // }
            
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
}
