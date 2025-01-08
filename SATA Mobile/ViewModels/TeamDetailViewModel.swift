import Foundation
import SwiftUI

@MainActor
class TeamDetailViewModel: ObservableObject {
    @Published var teamStats = TeamStats()
    @Published var state: ViewState = .loading
    @Published var recentForm: [String] = []
    @Published var nextMatch: NextMatch?
    @Published var squad: [Player] = []
    @Published var matches: [Match] = []
    
    func fetchTeamDetails(teamId: String) async {
        // Simulate fetching data
        teamStats = TeamStats(
            matches: 38,
            wins: 25,
            losses: 8,
            goalsFor: 80,
            goalsAgainst: 35,
            cleanSheets: 15
        )
        
        recentForm = ["W", "W", "D", "L", "W"]
        
        nextMatch = NextMatch(
            opponent: "Sporting CP",
            date: "2024-03-15",
            competition: "League Cup"
        )
        
        // Fetch squad and matches data...
    }

  func fetchTeamPlayers(team_Id: String) async {
        print("📱 Starting to fetch players for team ID: \(team_Id)")
        state = .loading
        
        guard let url = URL(string: "http://144.24.177.214:5000/clubs/\(team_Id)/players") else {
            print("❌ Invalid URL for team players endpoint")
            state = .error("Invalid URL")
            return
        }
      
              
        do {
            print("🌐 Fetching team players from network...")
            let (data, _) = try await URLSession.shared.data(from: url)
            print("✅ Team players data received: \(data.count) bytes")
            
            // Print received JSON for debugging
            // if let jsonString = String(data: data, encoding: .utf8) {
               // print("📄 Received JSON: \(jsonString)")
            // }

            
            do {
                squad = try JSONDecoder().decode([Player].self, from: data)
                print("📊 Successfully decoded \(squad.count) players")
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


struct TeamStats {
    var matches: Int = 0
    var wins: Int = 0
    var losses: Int = 0
    var goalsFor: Int = 0
    var goalsAgainst: Int = 0
    var cleanSheets: Int = 0
}

struct NextMatch {
    let opponent: String
    let date: String
    let competition: String
}

struct Match: Identifiable {
    let id = UUID()
    let opponent: String
    let date: String
    let score: String
    let result: String
    let competition: String
}
