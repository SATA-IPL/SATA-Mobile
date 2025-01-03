import Foundation

@MainActor
class TeamsViewModel: ObservableObject {
    @Published var teams: [Team] = []
    @Published var state: ViewState = .loading
    
    var teamNames: [String] {
        teams.map { $0.name }.sorted()
    }

    func fetchTeams() async {
        print("📱 Starting to fetch teams")
        state = .loading
        
        guard let url = URL(string: "http://144.24.177.214:5000/clubs") else {
            print("❌ Invalid URL for teams endpoint")
            return
        }
        
        do {
            print("🌐 Fetching teams from network...")
            let (data, _) = try await URLSession.shared.data(from: url)
            print("✅ Teams data received: \(data.count) bytes")
            
            // Print received JSON for debugging
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📄 Received JSON: \(jsonString)")
            }
            
            do {
                teams = try JSONDecoder().decode([Team].self, from: data)
                print("📊 Successfully decoded \(teams.count) teams")
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
    
    func SetTeam(team: Team) {
        //Save team id to App Storage
        let teamId = team.id
        UserDefaults.standard.set(teamId, forKey: "teamId")
    }
}
