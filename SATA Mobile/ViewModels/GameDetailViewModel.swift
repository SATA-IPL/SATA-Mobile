import Foundation
import GoogleGenerativeAI
import SwiftUI
import EventSource
import Combine

@MainActor
class GameDetailViewModel: ObservableObject {
    @Published var game: Game?
    @Published var state: ViewState = .loading
    @Published var isLoading = false
    @Published var response: LocalizedStringKey = "How can I help you today?"
    @Published var events: [Event] = [] {
        didSet {
            //print("📊 Events updated: \(events.count) events")
        }
    }
    @Published var homeStatistics: [Statistics] = []
    @Published var awayStatistics: [Statistics] = []
    @Published var draws: Int = 0
    @Published var team1Wins: Int = 0
    @Published var team2Wins: Int = 0
    @Published var team1Score: Int = 0
    @Published var team2Score: Int = 0
    @Published var homeLastResults: [String] = []
    @Published var awayLastResults: [String] = []
    @Published var predictedWinner: String?
    private var eventSource: EventSource?
    private var listeningTask: Task<Void, Never>?
    
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

    func fetchHomeStatistics(gameId: Int) async {
        print("📱 Starting to fetch Statistics for game ID: \(gameId)")
        
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

    func startListeningToEvents(gameId: Int) {
        listeningTask = Task {
            guard let url = URL(string: "http://144.24.177.214:5000/events/stream/\(gameId)") else { return }
            //guard let url = URL(string: "http://localhost:5002/events/stream/33") else { return }
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "GET"

            let eventSource = EventSource()
            let dataTask = await eventSource.dataTask(for: urlRequest)

            // Event handlers
            for await event in await dataTask.events() {
                switch event {
                case .open:
                    print("Connection was opened.")
                case .error(let error):
                        print("Received an error:", error.localizedDescription)
                case .event(let event):
                    let eventData = event.data ?? ""
                    
                    if let eventData = eventData.data(using: .utf8) {
                        do {
                            let newEvent = try JSONDecoder().decode(Event.self, from: eventData)
                            DispatchQueue.main.async {
                                print("📊 Successfully decoded event:", newEvent)
                                self.events.append(newEvent)
                            }
                        } catch {
                            print("❌ Failed to decode event data:", error)
                        }
                    } else {
                        print("❌ Failed to convert event data to Data")
                    }
                case .closed:
                    print("Connection was closed.")
                }
            }
        }
    }

    func stopListeningToEvents() {
        listeningTask?.cancel()
        listeningTask = nil
        print("Stopped listening to events.")
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
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📄 Received JSON: \(jsonString)")
            }
            
            let events = try JSONDecoder().decode([Event].self, from: data)
            await MainActor.run {
                self.events = events
            }
            print("📊 Successfully decoded \(events.count) events")
        } catch {
            print("❌ Error fetching events: \(error.localizedDescription)")
        }
    }

    func startListeningToGameDetails(gameId: Int) {
        listeningTask = Task {
            guard let url = URL(string: "http://144.24.177.214:5000/games/stream/\(gameId)") else { return }
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "GET"

            let eventSource = EventSource()
            let dataTask = await eventSource.dataTask(for: urlRequest)

            // Event handlers
            for await event in await dataTask.events() {
                switch event {
                case .open:
                    print("Connection was opened.")
                case .error(let error):
                    print("Received an error:", error.localizedDescription)
                case .event(let event):
                    let eventData = event.data ?? ""
                    
                    if let eventData = eventData.data(using: .utf8) {
                        do {
                            let updatedGame = try JSONDecoder().decode(Game.self, from: eventData)
                            DispatchQueue.main.async {
                                print("📊 Successfully decoded game details:", updatedGame)
                                self.game = updatedGame
                            }
                        } catch {
                            print("❌ Failed to decode game data:", error)
                        }
                    } else {
                        print("❌ Failed to convert game data to Data")
                    }
                case .closed:
                    print("Connection was closed.")
                }
            }
        }
    }

    func stopListeningToGameDetails() {
        listeningTask?.cancel()
        listeningTask = nil
        print("Stopped listening to game details.")
    }
        
    func fetchHeadToHead(team1Id: Int, team2Id: Int ) async {
            print("📱 Starting to fetch head to head stats for teams: \(team1Id) vs \(team2Id)")
            
            guard let url = URL(string: "http://144.24.177.214:5000/clubs/\(team1Id)/vs/\(team2Id)") else {
                print("❌ Invalid URL for head to head endpoint")
                return
            }
            
            do {
                print("🌐 Fetching head to head stats from network...")
                let (data, _) = try await URLSession.shared.data(from: url)
                print("✅ Head to head data received: \(data.count) bytes")
                
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("📄 Received JSON: \(jsonString)")
                }
                
                let stats = try JSONDecoder().decode(HeadToHeadStats.self, from: data)
                await MainActor.run {
                    self.draws = stats.draws
                    self.team1Wins = stats.team1_wins
                    self.team2Wins = stats.team2_wins
                    
                    if let lastGame = stats.games.first {
                        if (lastGame.home_team == stats.team1_id) {
                            self.team1Score = lastGame.home_score
                            self.team2Score = lastGame.away_score
                        }
                        
                        else {
                            self.team1Score = lastGame.away_score
                            self.team2Score = lastGame.home_score
                        }
                    } else {
                        self.team1Score = -1
                        self.team2Score = -1
                    }
                }
                print("📊 Successfully decoded head to head stats")
            } catch {
                print("❌ Error fetching head to head stats: \(error)")
            }
        }
        
    func fetchFormGuide(teamId: Int, isHome: Bool) async {
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
            await MainActor.run {
                if isHome {
                    self.homeLastResults = games.map { $0.result }
                } else {
                    self.awayLastResults = games.map { $0.result }
            }
            }
            print("📊 Successfully decoded last games")
            
        } catch {
            print("❌ Error fetching last games: \(error)")
        }
    }

    func predictWinner(gameId: Int) async {
        guard let url = URL(string: "http://144.24.177.214:5000/games/predict") else {
            print("❌ Invalid URL for prediction endpoint")
            return
        }
        
        do {
            print("🎲 Fetching game prediction...")
            let (data, _) = try await URLSession.shared.data(from: url)
            
            // Print received JSON for debugging
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📄 Received prediction JSON: \(jsonString)")
            }
            
            struct Prediction: Codable {
                let likely_winner: Int
            }
            
            let prediction = try JSONDecoder().decode(Prediction.self, from: data)
            print("🎯 Decoded prediction winner: \(prediction.likely_winner)")
            await MainActor.run {
                self.predictedWinner = String(prediction.likely_winner)
                print("✅ Set predicted winner to: \(prediction.likely_winner)")
            }
        } catch {
            print("❌ Error fetching prediction: \(error.localizedDescription)")
        }
    }

    func generateContext(game: Game) async -> String {
        // Fetch game details if we haven't already
        if self.game == nil {
            await fetchGameDetail(id: game.id)
            await fetchHomeStatistics(gameId: game.id)
            await fetchAwayStatistics(gameId: game.id)
            await fetchEvents(gameId: game.id)
        }
        
        //Start Listening to Events
        startListeningToEvents(gameId: game.id)
        
        // Use the fetched game data if available, otherwise use the passed game
        let contextGame = self.game ?? game
        
        var context = """
            Game Info:
            - Match: \(contextGame.homeTeam.name) vs \(contextGame.awayTeam.name)
            - Score: \(contextGame.homeScore)-\(contextGame.awayScore)
            - Date: \(contextGame.date)
            - Time: \(contextGame.hour)
            - Status: \(contextGame.state)
            """

        if let stadium = contextGame.stadium {
            context += "\n- Stadium: \(stadium.stadiumName)"
        }

        // Debug print to check players
        print("Home team players: \(String(describing: contextGame.homeTeam.players?.count))")
        print("Away team players: \(String(describing: contextGame.awayTeam.players?.count))")

        // Add team information
        if let homePlayers = contextGame.homeTeam.players {
            context += "\n\nHome Team Players (\(contextGame.homeTeam.name)):"
            for player in homePlayers {
                context += "\n- \(player.name) (#\(player.shirtNumber), \(player.position))"
            }
        }
        
        if let awayPlayers = contextGame.awayTeam.players {
            context += "\n\nAway Team Players (\(contextGame.awayTeam.name)):"
            for player in awayPlayers {
                context += "\n- \(player.name) (#\(player.shirtNumber), \(player.position))"
            }
        }

        //Stats
        if !homeStatistics.isEmpty {
            context += "\n\nHome Team Statistics:"
            for stat in homeStatistics {
                context += "\n- Assists: \(stat.assist)"
                context += "\n- Corners: \(stat.corner)"
                context += "\n- Defenses: \(stat.defense)"
                context += "\n- Finishes: \(stat.finish)"
                context += "\n- Fouls: \(stat.foul)"
                context += "\n- Free Kicks: \(stat.freeKick)"
                context += "\n- Goals: \(stat.goal)"
                context += "\n- Interceptions: \(stat.interception)"
                context += "\n- Offsides: \(stat.offside)"
                context += "\n- Passes: \(stat.passes)"
                context += "\n- Penalties: \(stat.penalty)"
                context += "\n- Red Cards: \(stat.redCard)"
                context += "\n- Substitutions: \(stat.substitution)"
                context += "\n- Tackles: \(stat.tackle)"
                context += "\n- Yellow Cards: \(stat.yellowCard)"
            }
        }

        if !awayStatistics.isEmpty {
            context += "\n\nAway Team Statistics:"
            for stat in awayStatistics {
                context += "\n- Assists: \(stat.assist)"
                context += "\n- Corners: \(stat.corner)"
                context += "\n- Defenses: \(stat.defense)"
                context += "\n- Finishes: \(stat.finish)"
                context += "\n- Fouls: \(stat.foul)"
                context += "\n- Free Kicks: \(stat.freeKick)"
                context += "\n- Goals: \(stat.goal)"
                context += "\n- Interceptions: \(stat.interception)"
                context += "\n- Offsides: \(stat.offside)"
                context += "\n- Passes: \(stat.passes)"
                context += "\n- Penalties: \(stat.penalty)"
                context += "\n- Red Cards: \(stat.redCard)"
                context += "\n- Substitutions: \(stat.substitution)"
                context += "\n- Tackles: \(stat.tackle)"
                context += "\n- Yellow Cards: \(stat.yellowCard)"
            }
        }
        
        // Event log
        context += "\n\nEvent Log:"
        for event in events {
            let player = contextGame.homeTeam.players?.first(where: { $0.id == event.player_id })
            let teamName: String
            let playerName: String
            
            if let homePlayer = player {
                teamName = contextGame.homeTeam.name
                playerName = homePlayer.name
            } else if let awayPlayer = contextGame.awayTeam.players?.first(where: { $0.id == event.player_id }) {
                teamName = contextGame.awayTeam.name
                playerName = awayPlayer.name
            } else {
                teamName = "Unknown Team"
                playerName = "Unknown Player"
            }
            
            context += "\n- \(event.event_type): \(teamName) - \(playerName)"
        }

        return context
    }
}

