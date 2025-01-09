import Foundation
import SwiftUI

@MainActor
class TeamDetailViewModel: ObservableObject {
    @Published var state: ViewState = .loading
    @Published var teamStats = TeamStats()
    @Published var recentForm: [String] = []
    @Published var nextMatch: Game?
    @Published var squad: [Player] = []
    @Published var games: [Game] = []
    @Published var upcomingGames: [Game] = []
    @Published var teamLastResults: [String] = [] 
    
    func fetchTeamDetails(teamId: String) async {
        // Simulate fetching team stats
        teamStats = TeamStats(
            matches: 38,
            wins: 25,
            losses: 8,
            goalsFor: 80,
            goalsAgainst: 35,
            cleanSheets: 15
        )
        
        // Load upcoming games
        await fetchUpcomingGames(teamId: Int(teamId) ?? 0)
    }

    func fetchUpcomingGames(teamId: Int) async {
        print("📱 Fetching upcoming games for team ID: \(teamId)")
        
        guard let url = URL(string: "http://144.24.177.214:5000/upcoming/\(teamId)") else {
            print("❌ Invalid URL for upcoming games endpoint")
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            if (data.isEmpty || String(data: data, encoding: .utf8) == "[]") {
                upcomingGames = []
                return
            }
            
            do {
                let games = try JSONDecoder().decode([Game].self, from: data)
                upcomingGames = games
                
            } catch {
                print("❌ Error decoding games: \(error.localizedDescription)")
                upcomingGames = []
            }
            
        } catch {
            print("❌ Error fetching upcoming games: \(error.localizedDescription)")
            upcomingGames = []
        }
    }

    func getFormattedGameDate(_ game: Game) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        guard let date = dateFormatter.date(from: game.date) else { return game.date }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let gameDay = calendar.startOfDay(for: date)
        
        let dayDifference = calendar.dateComponents([.day], from: today, to: gameDay).day ?? 0
        
        switch dayDifference {
        case 0: return "Today"
        case 1: return "Tomorrow"
        default:
            dateFormatter.dateFormat = "EEEE, MMMM d"
            return dateFormatter.string(from: date)
        }
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


   func fetchFormGuide(teamId: Int) async {
        print("📱 Starting to fetch last games for team: \(teamId)")
        
        guard let url = URL(string: "http://144.24.177.214:5000/clubs/\(teamId)/last") else {
            print("❌ Invalid URL for last games endpoint")
            return
        }
        
        do {
            print("🌐 Fetching last games from network...")
            let (data, _) = try await URLSession.shared.data(from: url)
            print("✅ Last games data received: \(data.count) bytes")
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📄 Received JSON: \(jsonString)")
            }
            
            let games = try JSONDecoder().decode([LastGame].self, from: data)
            self.teamLastResults = games.map { $0.result }
            print("📊 Successfully decoded last games")
            
        } catch {
            print("❌ Error fetching last games: \(error)")
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
}
