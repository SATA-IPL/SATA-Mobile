import AppIntents
import SwiftUI

struct LaunchAppIntent: AppIntent {
    static var title: LocalizedStringResource = "Launch My App"
    static var openAppWhenRun: Bool = true
    
    static var description: String = "Opens the app"

    func perform() async throws -> some IntentResult {
        // The app will open automatically since openAppWhenRun is true
        return .result()
    }
}

struct ShowTeamGames: AppIntent {
    static var title: LocalizedStringResource = "Show Team Games"
    static var openAppWhenRun: Bool = true
    
    static var description: String = "Shows the games of a team"

    func perform() async throws -> some IntentResult {
        NotificationCenter.default.post(name: Notification.Name("OpenMyTeamView"), object: nil)
        return .result()
    }
}

struct NextTeamMatchIntent: AppIntent {
    static var title: LocalizedStringResource = "Next Team Match"
    static var openAppWhenRun: Bool = false
    
    static var description: String = "Tells you when your team's next match is."

    @Parameter(title: "Response")
    var response: String
    
    init() {
        self.response = "How can I help you today?"
    }
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        await fetchUpcomingGameOfFavouriteTeam()
        return .result(dialog: IntentDialog(stringLiteral: response))
    }

    func fetchUpcomingGameOfFavouriteTeam() async {
        let favoriteTeamId = UserDefaults.standard.integer(forKey: "teamId")
        if (favoriteTeamId != 0) {
            await fetchUpcomingGame(teamId: favoriteTeamId)
        } else {
            response = "Please select a favorite team on SATA first."
        }
    }
    
    func fetchUpcomingGame(teamId: Int) async {
        print("📱 Fetching upcoming game for team ID: \(teamId)")
        
        guard let url = URL(string: "http://144.24.177.214:5000/upcoming/\(teamId)") else {
            print("❌ Invalid URL for upcoming game endpoint")
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            // First check if response is empty or just "{}"
            if data.isEmpty || String(data: data, encoding: .utf8) == "{}" {
                response = "There are no scheduled games for your team at the moment."
                return
            }
            
            // Only try to decode if we have actual data
            struct UpcomingGame: Codable {
                let away_team: Team
                let home_team: Team
                let date: String
                let hour: String
                
                struct Team: Codable {
                    let name: String
                    let id: Int
                }
            }
            
            do {
                let game = try JSONDecoder().decode(UpcomingGame.self, from: data)
                
                // Format date for natural language
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                let date = dateFormatter.date(from: game.date) ?? Date()
                
                let calendar = Calendar.current
                let today = calendar.startOfDay(for: Date())
                let gameDay = calendar.startOfDay(for: date)
                
                let dayDifference = calendar.dateComponents([.day], from: today, to: gameDay).day ?? 0
                
                let dayText: String
                switch dayDifference {
                case 0: dayText = "Today"
                case 1: dayText = "Tomorrow"
                default: 
                    dateFormatter.dateFormat = "EEEE, MMMM d"
                    dayText = "on \(dateFormatter.string(from: date))"
                }
                
                // Generate natural language response
                let opponent = game.home_team.id == teamId ? game.away_team.name : game.home_team.name
                let message = "Your next match is \(dayText) at \(game.hour) against \(opponent)"
                
                response = message
                
            } catch DecodingError.keyNotFound(_, _) {
                response = "There are no scheduled games for your team at the moment."
                return
            } catch {
                print("❌ Error decoding game: \(error.localizedDescription)")
                response = "Sorry, I couldn't fetch the upcoming game information."
                return
            }
            
        } catch {
            print("❌ Error fetching upcoming game: \(error.localizedDescription)")
            response = "Sorry, I couldn't fetch the upcoming game information."
        }
    }
}

struct ShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
            AppShortcut(
                intent: LaunchAppIntent(),
                phrases: ["Open SATA Mobile", "Launch SATA Mobile", "Start SATA Mobile", "Open SATA", "Launch SATA", "Start SATA", "Open \(.applicationName)", "Launch \(.applicationName)", "Start \(.applicationName)"],
                shortTitle: "Open App",
                systemImageName: "app"
            )
            AppShortcut(
                intent: ShowTeamGames(),
                phrases: ["Show my team's games", "View team schedule", "Check team games", "Show my team's games on \(.applicationName)", "View team schedule on \(.applicationName)", "Check team games on \(.applicationName)"],
                shortTitle: "Team Games",
                systemImageName: "calendar"
            )
            AppShortcut(
                intent: NextTeamMatchIntent(),
                phrases: ["When is my next match?", "Next game", "When do we play next?", "Check on \(.applicationName) when is my next match?", "Check on \(.applicationName) next game", "Check on \(.applicationName) when do we play next?"],
                shortTitle: "Next Match",
                systemImageName: "sportscourt"
            )
    }
}
