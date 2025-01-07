import Foundation

@MainActor
class TeamDetailViewModel: ObservableObject {
    @Published var teamStats = TeamStats()
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
