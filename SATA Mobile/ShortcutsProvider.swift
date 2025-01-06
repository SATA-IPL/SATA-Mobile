import AppIntents

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
    
    static var description: String = "Tells you when is your team's next match"

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // This is a placeholder - you should get this data from your GamesViewModel
        let nextMatch = "Tomorrow at 8 PM against Benfica" // Replace with actual data
        
        return .result(dialog: IntentDialog(stringLiteral: "Your next match is \(nextMatch)"))
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
