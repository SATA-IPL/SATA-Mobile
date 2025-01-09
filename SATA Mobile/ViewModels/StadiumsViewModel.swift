import Foundation

@MainActor
class StadiumsViewModel: ObservableObject {
    @Published var stadiums: [Stadium] = []
    @Published var state: ViewState = .loading
    @Published var showFavoritesOnly = false
    
    var filteredStadiums: [Stadium] {
        showFavoritesOnly ? stadiums.filter { $0.isFavorite } : stadiums
    }
    
    func toggleFavorite(for stadium: Stadium) {
        if let index = stadiums.firstIndex(where: { $0.id == stadium.id }) {
            stadiums[index].isFavorite.toggle()
            FavoriteStadiums.shared.toggleFavorite(stadiumId: stadium.id)
        }
    }
    
    func fetchStadiums() async {
        print("📱 Starting to fetch games")
        state = .loading
        
        guard let url = URL(string: "http://144.24.177.214:5000/stadiums") else {
            print("❌ Invalid URL for games endpoint")
            return
        }
        
        do {
            print("🌐 Fetching games from network...")
            let (data, _) = try await URLSession.shared.data(from: url)
            print("✅ Games data received: \(data.count) bytes")
            
            // Print received JSON for debugging
            // if let jsonString = String(data: data, encoding: .utf8) {
            //     print("📄 Received JSON: \(jsonString)")
            // }
            
            do {
                stadiums = try JSONDecoder().decode([Stadium].self, from: data)
                // Update favorites status from stored favorites
                for index in stadiums.indices {
                    stadiums[index].isFavorite = FavoriteStadiums.shared.isFavorite(stadiumId: stadiums[index].id)
                }
                print("📊 Successfully decoded \(stadiums.count) games")
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
    
    func fetchStadium(teamId: String) async -> Stadium? {
        print("📱 Starting to fetch stadium")
        state = .loading
        
        guard let url = URL(string: "http://144.24.177.214:5000/stadiums/\(teamId)") else {
            print("❌ Invalid URL for stadium endpoint")
            return nil
        }
        
        do {
            print("🌐 Fetching stadium from network...")
            let (data, _) = try await URLSession.shared.data(from: url)
            print("✅ Stadium data received: \(data.count) bytes")
            
            do {
                let stadium = try JSONDecoder().decode(Stadium.self, from: data)
                print("📊 Successfully decoded stadium")
                state = .loaded
                return stadium
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
                return nil
            }
        } catch {
            print("❌ Network error: \(error.localizedDescription)")
            state = .error(error.localizedDescription)
            return nil
        }
    }
}
