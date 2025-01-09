import Foundation

struct TeamStats {
    var matches: Int = 0
    var wins: Int = 0
    var losses: Int = 0
    var goalsFor: Int = 0
    var goalsAgainst: Int = 0
    var cleanSheets: Int = 0
}


@MainActor
class TeamsViewModel: ObservableObject {
    @Published var teams: [Team] = []
    @Published var state: ViewState = .loading
    @Published var team: Team?
    @Published private var selectedTeamId: String?
    
    // Added team details properties
    @Published var teamStats = TeamStats()
    @Published var recentForm: [String] = []
    @Published var nextMatch: Game?
    @Published var squad: [Player] = []
    @Published var matches: [Game] = []
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

    func fetchTeam(teamId: String) async -> Team? {
        guard let url = URL(string: "http://144.24.177.214:5000/clubs/\(teamId)") else {
            print("❌ Invalid URL for team endpoint")
            return nil
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let team = try JSONDecoder().decode(Team.self, from: data)
            self.team = team
            return team
        } catch {
            print("❌ Error fetching team: \(error.localizedDescription)")
            return nil
        }
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
        // Clear everything first
        clearTeamData()
        
        // Set new team
        self.team = team
        self.selectedTeamId = team.id
        UserDefaults.standard.set(team.id, forKey: "teamId")
        
        // Fetch new team data
        Task {
            await fetchTeamDetails()
        }
    }
    
    private func clearTeamData() {
        // Reset all team-specific data
        squad = []
        matches = []
        teamStats = TeamStats()
        recentForm = []
        nextMatch = nil
        state = .loading
        
        // Cancel any ongoing fetch
        fetchTask?.cancel()
        fetchTask = nil
    }
    
    func fetchTeamDetails() async {
        guard let teamId = currentTeam else { return }
        
        // Clear existing data before fetching new data
        clearTeamData()
        
        // Ensure we have the correct team object
        if let selectedTeam = teams.first(where: { $0.id == teamId }) {
            team = selectedTeam
        }
        
        // Fetch all team data
        do {
            // Fetch squad first
            await fetchTeamPlayers(team_Id: teamId)
            
            // Set other team details
            teamStats = TeamStats(
                matches: 38,
                wins: 25,
                losses: 8,
                goalsFor: 80,
                goalsAgainst: 35,
                cleanSheets: 15
            )
            
            recentForm = ["W", "W", "D", "L", "W"]
            
            state = .loaded
        } catch {
            state = .error("Failed to fetch team details")
        }
    }
    
    func fetchTeamPlayers(team_Id: String) async {
        // Cancel any existing fetch task
        fetchTask?.cancel()
        
        // Create new fetch task
        fetchTask = Task {
            guard let url = URL(string: "http://144.24.177.214:5000/clubs/\(team_Id)/players") else {
                return
            }
            
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if Task.isCancelled { return }
                
                let newSquad = try JSONDecoder().decode([Player].self, from: data)
                if !Task.isCancelled {
                    squad = newSquad
                }
            } catch {
                if !Task.isCancelled {
                    print("Error fetching players: \(error.localizedDescription)")
                }
            }
        }
        
        await fetchTask?.value
    }
    
    deinit {
        fetchTask?.cancel()
    }
}
