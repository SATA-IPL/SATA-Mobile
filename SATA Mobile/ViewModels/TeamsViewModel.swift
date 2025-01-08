import Foundation

@MainActor
class TeamsViewModel: ObservableObject {
    @Published var teams: [Team] = []
    @Published var state: ViewState = .loading
    @Published var team: Team?
    @Published private var selectedTeamId: String?
    
    // Added team details properties
    @Published var teamStats = TeamStats()
    @Published var recentForm: [String] = []
    @Published var nextMatch: NextMatch?
    @Published var squad: [Player] = []
    @Published var matches: [Match] = []
    @Published var games: [Game] = []
    
    private var fetchTask: Task<Void, Never>?
    
    var currentTeam: String? {
        selectedTeamId ?? UserDefaults.standard.string(forKey: "teamId")
    }
    
    var teamNames: [String] {
        teams.map { $0.name }.sorted()
    }

    var currentTeamName: String? {
        if let teamId = currentTeam,
           let team = teams.first(where: { $0.id == teamId }) {
            return team.name
        }
        return nil
    }

    var currentTeamImage: String? {
        if let teamId = currentTeam,
           let team = teams.first(where: { $0.id == teamId }) {
            return team.image
        }
        return nil
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
            // if let jsonString = String(data: data, encoding: .utf8) {
            //     print("📄 Received JSON: \(jsonString)")
            // }
            
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
    
    func setTeam(team: Team) {
        self.team = team
        let teamId = team.id
        UserDefaults.standard.set(teamId, forKey: "teamId")
        selectedTeamId = teamId
        
        // Clear existing squad data
        squad = []
        
        // Fetch team details when team is selected
        Task {
            await fetchTeamDetails()
        }
    }
    
    func fetchTeamDetails() async {
        guard let teamId = currentTeam else { return }
        
        if let selectedTeam = teams.first(where: { $0.id == teamId }) {
            team = selectedTeam
        }
        
        // Fetch team details using teamId
        // For now, using mock data
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
        
        // Fetch matches
        if let teamId = currentTeam {
            await fetchTeamMatches(teamId: teamId)
        }
        
        // Fetch squad and matches data...
    }
    
    func fetchTeamPlayers(team_Id: String) async {
        // Clear existing squad before fetching new data
        squad = []
        state = .loading

        // Cancel any existing fetch task
        fetchTask?.cancel()
        
        // Create new fetch task
        fetchTask = Task {
            guard let url = URL(string: "http://144.24.177.214:5000/clubs/\(team_Id)/players") else {
                state = .error("Invalid URL")
                return
            }
            
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                
                if Task.isCancelled { return }
                
                do {
                    squad = try JSONDecoder().decode([Player].self, from: data)
                    state = .loaded
                } catch {
                    state = .error("Decoding error: \(error.localizedDescription)")
                }
            } catch {
                if !Task.isCancelled {
                    state = .error(error.localizedDescription)
                }
            }
        }
        
        await fetchTask?.value
    }
    
    deinit {
        fetchTask?.cancel()
    }
    
    func fetchTeamMatches(teamId: String) async {
        // Simulate fetching match data
        matches = [
            Match(opponent: "FC Porto", date: "2024-03-10", score: "2-1", result: "W", competition: "Liga Portugal"),
            Match(opponent: "Benfica", date: "2024-03-03", score: "0-0", result: "D", competition: "Liga Portugal"),
            Match(opponent: "Sporting CP", date: "2024-02-25", score: "1-2", result: "L", competition: "Taça de Portugal"),
            // Add more matches as needed
        ]
    }
}
