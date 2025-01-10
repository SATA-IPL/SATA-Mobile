import SwiftUI
import AVKit
import GoogleGenerativeAI
import ActivityKit

/// A view that displays detailed information about a specific game
struct GameDetailView: View {
    // MARK: - Properties
    let game: Game
    let gameId: Int
    @StateObject private var viewModel = GameDetailViewModel()
    @EnvironmentObject private var stadiumsViewModel: StadiumsViewModel
    var animation: Namespace.ID
    @State private var showStadium = false
    @State private var showVideoPlayer = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var isStatsLoaded = true
    @State private var isEventsLoaded = true
    
    @State var userPrompt = ""
    @State private var isTextExpanded = false
    @State private var showChat = false
    @State private var messageText = ""
    @State private var isListening = false
    @State private var animationScale: CGFloat = 1.0
    @State private var activity: Activity<GameActivityAttributes>?
    @State private var isLoading = true 
    @State private var timer: Timer?
    
    // MARK: - Live Activity Management
    /// Starts the Live Activity for the current game
    private func startLiveActivity() {
        Task {
            if let detailedGame = viewModel.game {
                let gameTime = calculateGameTime(from: detailedGame.timestamp)
                let attributes = GameActivityAttributes(
                    homeTeam: game.homeTeam.name,
                    awayTeam: game.awayTeam.name,
                    homeTeamColor: game.homeTeam.colors?[0] ?? "#FFFFFF",
                    awayTeamColor: game.awayTeam.colors?[0] ?? "#00C0FF"
                )
                
                let contentState = GameActivityAttributes.ContentState(
                    homeScore: detailedGame.homeScore,
                    awayScore: detailedGame.awayScore,
                    gameStatus: game.state,
                    gameTime: gameTime,
                    lastEvent: viewModel.events.first.map { event ->  String in
                        let playerName = getPlayerName(id: event.player_id, in: detailedGame)
                        return "\(event.event_type): \(playerName)"
                    } ?? "No events"
                )
                
                activity = try? Activity<GameActivityAttributes>.request(
                    attributes: attributes,
                    contentState: contentState,
                    pushType: nil
                )
            }
        }
    }
    
    /// Stops the current Live Activity
    private func stopLiveActivity() {
        Task {
            await activity?.end(nil, dismissalPolicy: .immediate)
        }
    }

    /// Updates the Live Activity with new score information
    /// - Parameters:
    ///   - homeScore: The home team's current score
    ///   - awayScore: The away team's current score
    private func updateLiveActivityScore(homeScore: Int, awayScore: Int) {
        Task {
            let gameTime = calculateGameTime(from: game.timestamp)
            let contentState = GameActivityAttributes.ContentState(
                homeScore: homeScore,
                awayScore: awayScore,
                gameStatus: game.state,
                gameTime: gameTime,
                lastEvent: "Score Update"
            )
            
            await activity?.update(using: contentState)
        }
    }

    // MARK: - Time Management
    /// Calculates the game time from a given timestamp
    /// - Parameter timestamp: The timestamp string to calculate from
    /// - Returns: A formatted string representing the game time
    private func calculateGameTime(from timestamp: String?) -> String {
        print("📅 Calculating game time from timestamp: \(timestamp ?? "nil")")
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSS"
        
        guard let timestamp = timestamp,
              let date = formatter.date(from: timestamp) else {
            print("⚠️ Invalid timestamp or failed to parse date")
            return "0'"
        }
        
        let elapsed = Int(-date.timeIntervalSinceNow / 60)  // Convert seconds to minutes
        let finalTime = "\(elapsed)'"  // Removed extra parenthesis
        print("⏱️ Calculated game time: \(finalTime)")
        return finalTime
    }

    /// Updates the Live Activity with a new event
    /// - Parameter event: The event to update with
    private func updateLiveActivityWithEvent(_ event: Event) {
        Task {
            if let detailedGame = viewModel.game {
                let playerName = getPlayerName(id: event.player_id, in: detailedGame)
                let gameTime = calculateGameTime(from: detailedGame.timestamp)
                
                let contentState = GameActivityAttributes.ContentState(
                    homeScore: viewModel.game?.homeScore ?? 0,
                    awayScore: viewModel.game?.awayScore ?? 0,
                    gameStatus: game.state,
                    gameTime: gameTime,
                    lastEvent: "\(event.event_type): \(playerName)"
                )
                
                await activity?.update(using: contentState)
            }
        }
    }

    // MARK: - Helper Functions
    /// Gets a player's name from their ID
    /// - Parameters:
    ///   - id: The player's ID
    ///   - game: The current game
    /// - Returns: The player's name or "Unknown" if not found
    private func getPlayerName(id: String?, in game: Game) -> String {
        guard let playerId = id else { return "Unknown" }
        
        // Check home team players
        if let homePlayers = game.homeTeam.players,
           let player = homePlayers.first(where: { $0.id == playerId }) {
            return player.name
        }
        
        // Check away team players
        if let awayPlayers = game.awayTeam.players,
           let player = awayPlayers.first(where: { $0.id == playerId }) {
            return player.name
        }
        
        return "Unknown"
    }

    /// Starts the timer for updating game time
    private func startGameTimeUpdates() {
        timer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
            if let detailedGame = viewModel.game {
                updateLiveActivityTime(game: detailedGame)
            }
        }
    }
    
    /// Stops the game time update timer
    private func stopGameTimeUpdates() {
        timer?.invalidate()
        timer = nil
    }
    
    /// Updates the Live Activity with the current game time
    /// - Parameter game: The current game
    private func updateLiveActivityTime(game: Game) {
        Task {
            let gameTime = calculateGameTime(from: game.timestamp)
            let lastEventText = viewModel.events.max(by: { $0.id < $1.id }).map { event -> String in
                let playerName = getPlayerName(id: event.player_id, in: game)
                return "\(event.event_type): \(playerName)"
            } ?? "No events"
            
            let contentState = GameActivityAttributes.ContentState(
                homeScore: game.homeScore,
                awayScore: game.awayScore,
                gameStatus: game.state,
                gameTime: gameTime,
                lastEvent: lastEventText
            )
            await activity?.update(using: contentState)
        }
    }

    // MARK: - Game Sections
    /// Enum defining the different sections of the game detail view
    enum GameSection: String, CaseIterable {
        case overview = "Overview"
        case analysis = "Analysis"
        case lineups = "Lineups"
    }
    
    @State private var selectedSection: GameSection = .overview
    
    // MARK: - View Body
    var body: some View {
        NavigationStack {
            ZStack {
                if isLoading {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.secondary)
                        Text("Loading game details...")
                            .foregroundStyle(.secondary)
                            .padding(.top)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity) // Add this line
                    .background {
                        gameBackground(
                            homeTeamColor: game.homeTeam.colors?[0] ?? "#FFFFFF",
                            awayTeamColor: game.awayTeam.colors?[0] ?? "#00C0FF"
                        )
                    }
                } else {
                    ScrollView{
                        VStack(spacing: 0) {
                            // Game header with teams and score
                            if let detailedGame = viewModel.game {
                                HStack(spacing: 0) {
                                    TeamView(team: detailedGame.homeTeam, score: detailedGame.homeScore)
                                    Spacer()
                                    HStack {
                                        VStack {
                                            Text(detailedGame.hour)
                                                .font(.system(.title2, weight: .bold).width(.compressed))
                                            let formattedDate = detailedGame.date.components(separatedBy: "-").reversed().joined(separator: "/")
                                            Text(formattedDate)
                                                .font(.system(.headline, weight: .bold).width(.compressed))
                                                .foregroundStyle(.secondary)
                                            Text(detailedGame.state.capitalized)
                                                .font(.system(.caption, weight: .bold))
                                                .foregroundStyle(.white)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(.ultraThinMaterial)
                                                .clipShape(.capsule)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    TeamView(team: detailedGame.awayTeam, score: detailedGame.awayScore)
                                }
                                .padding(.horizontal, 35)
                                if(detailedGame.state == "live" || detailedGame.state == "finished"){
                                    PillButton(
                                        action: { showVideoPlayer.toggle() },
                                        title: "Watch on SATA+",
                                        icon: "play.circle.fill"
                                    )
                                    .padding(.top, 10)
                                }
                            }
                            
                            
                            // Replace old Picker with new custom control
                            CustomSegmentedControl(selectedSection: $selectedSection, sections: GameSection.allCases)
                                .padding(.vertical, 16)
                            
                            VStack(spacing: 20) {
                                switch selectedSection {
                                case .overview:
                                    overviewSection
                                case .analysis:
                                    analysisSection
                                case .lineups:
                                    lineupsSection
                                }
                            }
                        }
                    }
                    .navigationTransition(.zoom(sourceID: game.id, in: animation))
                    .background {
                        gameBackground(
                            homeTeamColor: game.homeTeam.colors?[0] ?? "#FFFFFF",
                            awayTeamColor: game.awayTeam.colors?[0] ?? "#00C0FF"
                        )
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showVideoPlayer) {
            VideoPlayerView(videoURL: URL(string: "https://github.com/FranciscoMarques1/Video_test/raw/refs/heads/main/real%20video.mp4")!, title: "Title", subtitle: "Subtitle")
                .presentationBackground(.clear)
                .ignoresSafeArea()
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            isLoading = true
            await viewModel.fetchGameDetail(id: gameId)
            await viewModel.fetchHomeStatistics(gameId: gameId)
            await viewModel.fetchAwayStatistics(gameId: gameId)
            await viewModel.predictWinner(gameId: gameId)  // Add this line
            if let homeTeamId = Int(game.homeTeam.id),
                let awayTeamId = Int(game.awayTeam.id) {
                await viewModel.fetchHeadToHead(team1Id: homeTeamId, team2Id: awayTeamId)
             }   
             await viewModel.fetchFormGuide(teamId: Int(game.homeTeam.id) ?? 0, isHome: true)
            await viewModel.fetchFormGuide(teamId: Int(game.awayTeam.id) ?? 0, isHome: false)
            isStatsLoaded = true
            isEventsLoaded = true
            if let game = viewModel.game {
                print("Fetched home statistics:", viewModel.homeStatistics)
                print("Fetched away statistics:", viewModel.awayStatistics)
                //print("Fetched game details:", game)
                // Start live activity for demo purposes, regardless of game state
                if (game.state == "live") {
                    startLiveActivity()
                    startGameTimeUpdates()
                }
            }
            isLoading = false
        }
        .onAppear {
            viewModel.startListeningToGameDetails(gameId: gameId)
        }
        .onDisappear {
            Task {
                stopGameTimeUpdates()
                stopLiveActivity()
                viewModel.stopListeningToGameDetails()
            }
        }
        .onChange(of: viewModel.game?.homeScore) { newHomeScore in
            if let homeScore = newHomeScore,
               let awayScore = viewModel.game?.awayScore {
                updateLiveActivityScore(homeScore: homeScore, awayScore: awayScore)
            }
        }
        .onChange(of: viewModel.game?.awayScore) { newAwayScore in
            if let homeScore = viewModel.game?.homeScore,
               let awayScore = newAwayScore {
                updateLiveActivityScore(homeScore: homeScore, awayScore: awayScore)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button(action: { showChat.toggle() }) {
                    Image(systemName: "bubble.left.and.bubble.right")
                }
                Button(action: { showStadium.toggle() }) {
                    Image(systemName: "sportscourt")
                }
                .disabled(viewModel.game?.stadium == nil)
            }
        }
        .sheet(isPresented: $showStadium) {
            if let stadium = viewModel.game?.stadium {
                StadiumView(viewModel: stadiumsViewModel, stadium: stadium)
            }
        }
        .fullScreenCover(isPresented: $showChat) {
            ChatView(game: game, model: viewModel.model, isPresented: $showChat)
        }
    }
    
    // MARK: - Section Views
    /// View for the overview section
    private var overviewSection: some View {
        VStack(spacing: 12) {
            switch viewModel.state {
            case .loading:
                loadingAdditionalInfo
            case .error(let message):
                ContentUnavailableView {
                    Label("Unable to Load Details", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(message)
                }
            case .loaded:
                if let detailedGame = viewModel.game {
                    if(game.state == "live" || game.state == "finished")
                    {
                        matchStatsCard(game, viewModel, isStatsLoaded: isStatsLoaded)
                        eventsCard(
                            game,
                            viewModel,
                            gameId: gameId,
                            updateLiveActivityScore: updateLiveActivityWithEvent
                        )
                        .onAppear {
                            print("📊 Events in viewModel: \(viewModel.events)")
                        }
                    }
                    else {
                        // Move prediction card outside of detailedGame check since it's independent
                        if let predictedWinner = viewModel.predictedWinner {
                            InfoCard(title: "Match Prediction", icon: "trophy.fill") {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 16) {
                                        let winningTeam = (predictedWinner == detailedGame.homeTeam.id) ? detailedGame.homeTeam : detailedGame.awayTeam
                                        if let imageUrl = winningTeam.image {
                                            AsyncImage(url: URL(string: imageUrl)) { image in
                                                image.resizable()
                                                    .aspectRatio(contentMode: .fit)
                                                    .frame(width: 50, height: 50)
                                            } placeholder: {
                                                Color.gray.opacity(0.3)
                                            }
                                            .frame(width: 50, height: 50)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Predicted Winner")
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                            Text(winningTeam.name)
                                                .font(.title3)
                                                .fontWeight(.bold)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                }
            }
        }
    }

    /// View for the analysis section
    private var analysisSection: some View {
        VStack(spacing: 20) {
            InfoCard(title: "Game Analysis", icon: "sparkles") {
                if viewModel.isLoading {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(0..<3) { _ in
                            ShimmerLoadingView()
                                .frame(height: 16)
                                .cornerRadius(8)
                        }
                    }
                } else {
                    Text(viewModel.response)
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .onAppear {
                if viewModel.response == "How can I help you today?" {
                    userPrompt = "Write a brief, engaging historical highlight about past matches between \(game.homeTeam.name) and \(game.awayTeam.name) with interesting facts for a description card. Just include response text. No Title"
                    Task {
                        await viewModel.generateResponse(userPrompt: userPrompt)
                    }
                }
            }
            
            headToHeadCard(game,viewModel)
            formGuideCard(game,viewModel)
        }
    }

    /// View for the lineups section
    private var lineupsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let detailedGame = viewModel.game {
                SoccerFieldView(homeTeam: detailedGame.homeTeam, awayTeam: detailedGame.awayTeam, gameId: gameId)
                    .aspectRatio(1.5, contentMode: .fit) // This will maintain aspect ratio while filling width
                    .padding(.horizontal)
                
                if let players = detailedGame.homeTeam.players {
                    TeamLineupView(team: detailedGame.homeTeam, players: players, gameId: gameId)
                }
                
                if let players = detailedGame.awayTeam.players {
                    TeamLineupView(team: detailedGame.awayTeam, players: players, gameId: gameId)
                }
            } else {
                loadingAdditionalInfo
            }
        }
    }

    // MARK: - UI Components

    /// Match Stats Card
    /// - Parameters:
    ///   - game: The current game
    ///   - viewModel: The view model for the game
    ///   - isStatsLoaded: Whether the stats have been loaded
    /// - Returns: A card displaying match statistics
    private func matchStatsCard(_ game: Game, _ viewModel: GameDetailViewModel,isStatsLoaded: Bool) -> some View {
        InfoCard(title: "Match Stats", icon: "chart.bar.fill") {
            VStack(spacing: CardStyle.spacing) {
                HStack(spacing: 0) {
                    StatColumn(
                        title: game.homeTeam.name,
                        values: [String(viewModel.homeStatistics.first?.finish ?? 0)]
                    )
                    StatColumn(title: "", values: ["Finishes"], isCenter: true)
                    StatColumn(
                        title: game.awayTeam.name,
                        values: [String(viewModel.awayStatistics.first?.finish ?? 0)]
                    )
                }
                
                StatBar(
                    leftValue: viewModel.homeStatistics.first?.finish ?? 0,
                    rightValue: viewModel.awayStatistics.first?.finish ?? 0,
                    leftColor: Color(hex: game.homeTeam.colors?[0] ?? "#FFFFFF"),
                    rightColor: Color(hex: game.awayTeam.colors?[0] ?? "#00C0FF")
                )
                .padding(.horizontal)
                .padding(.bottom, 8)
                
                // Add more stats with their respective bars...
                Group {
                    HStack(spacing: 0) {
                        StatColumn(title: "", values: [String(viewModel.homeStatistics.first?.passes ?? 0)])
                        StatColumn(title: "", values: ["Passes"], isCenter: true)
                        StatColumn(title: "", values: [String(viewModel.awayStatistics.first?.passes ?? 0)])
                    }
                    
                    StatBar(
                        leftValue: viewModel.homeStatistics.first?.passes ?? 0,
                        rightValue: viewModel.awayStatistics.first?.passes ?? 0,
                        leftColor: Color(hex: game.homeTeam.colors?[0] ?? "#FFFFFF"),
                        rightColor: Color(hex: game.awayTeam.colors?[0] ?? "#00C0FF")
                    )
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                    
                    HStack(spacing: 0) {
                        StatColumn(title: "", values: [String(viewModel.homeStatistics.first?.defense ?? 0)])
                        StatColumn(title: "", values: ["Saves"], isCenter: true)
                        StatColumn(title: "", values: [String(viewModel.awayStatistics.first?.defense ?? 0)])
                    }
                    
                    StatBar(
                        leftValue: viewModel.homeStatistics.first?.defense ?? 0,
                        rightValue: viewModel.awayStatistics.first?.defense ?? 0,
                        leftColor: Color(hex: game.homeTeam.colors?[0] ?? "#FFFFFF"),
                        rightColor: Color(hex: game.awayTeam.colors?[0] ?? "#00C0FF")
                    )
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                    
                    HStack(spacing: 0) {
                        StatColumn(title: "", values: [String(viewModel.homeStatistics.first?.interception ?? 0)])
                        StatColumn(title: "", values: ["Interceptions"], isCenter: true)
                        StatColumn(title: "", values: [String(viewModel.awayStatistics.first?.interception ?? 0)])
                    }
                    
                    StatBar(
                        leftValue: viewModel.homeStatistics.first?.interception ?? 0,
                        rightValue: viewModel.awayStatistics.first?.interception ?? 0,
                        leftColor: Color(hex: game.homeTeam.colors?[0] ?? "#FFFFFF"),
                        rightColor: Color(hex: game.awayTeam.colors?[0] ?? "#00C0FF")
                    )
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                    
                    HStack(spacing: 0) {
                        StatColumn(title: "", values: [String(viewModel.homeStatistics.first?.tackle ?? 0)])
                        StatColumn(title: "", values: ["Tackles"], isCenter: true)
                        StatColumn(title: "", values: [String(viewModel.awayStatistics.first?.tackle ?? 0)])
                    }
                    
                    StatBar(
                        leftValue: viewModel.homeStatistics.first?.tackle ?? 0,
                        rightValue: viewModel.awayStatistics.first?.tackle ?? 0,
                        leftColor: Color(hex: game.homeTeam.colors?[0] ?? "#FFFFFF"),
                        rightColor: Color(hex: game.awayTeam.colors?[0] ?? "#00C0FF")
                    )
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                    
                    HStack(spacing: 0) {
                        StatColumn(title: "", values: [String(viewModel.homeStatistics.first?.foul ?? 0)])
                        StatColumn(title: "", values: ["Fouls"], isCenter: true)
                        StatColumn(title: "", values: [String(viewModel.awayStatistics.first?.foul ?? 0)])
                    }
                    
                    StatBar(
                        leftValue: viewModel.homeStatistics.first?.foul ?? 0,
                        rightValue: viewModel.awayStatistics.first?.foul ?? 0,
                        leftColor: Color(hex: game.homeTeam.colors?[0] ?? "#FFFFFF"),
                        rightColor: Color(hex: game.awayTeam.colors?[0] ?? "#00C0FF")
                    )
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                    
                    HStack(spacing: 0) {
                        StatColumn(title: "", values: [String(viewModel.homeStatistics.first?.penalty ?? 0)])
                        StatColumn(title: "", values: ["Penalty Kicks"], isCenter: true)
                        StatColumn(title: "", values: [String(viewModel.awayStatistics.first?.penalty ?? 0)])
                    }
                    
                    StatBar(
                        leftValue: viewModel.homeStatistics.first?.penalty ?? 0,
                        rightValue: viewModel.awayStatistics.first?.penalty ?? 0,
                        leftColor: Color(hex: game.homeTeam.colors?[0] ?? "#FFFFFF"),
                        rightColor: Color(hex: game.awayTeam.colors?[0] ?? "#00C0FF")
                    )
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                    
                    HStack(spacing: 0) {
                        StatColumn(title: "", values: [String(viewModel.homeStatistics.first?.yellowCard ?? 0)])
                        StatColumn(title: "", values: ["Yellow Cards"], isCenter: true)
                        StatColumn(title: "", values: [String(viewModel.awayStatistics.first?.yellowCard ?? 0)])
                    }
                    
                    StatBar(
                        leftValue: viewModel.homeStatistics.first?.yellowCard ?? 0,
                        rightValue: viewModel.awayStatistics.first?.yellowCard ?? 0,
                        leftColor: Color(hex: game.homeTeam.colors?[0] ?? "#FFFFFF"),
                        rightColor: Color(hex: game.awayTeam.colors?[0] ?? "#00C0FF")
                    )
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                    
                    HStack(spacing: 0) {
                        StatColumn(title: "", values: [String(viewModel.homeStatistics.first?.redCard ?? 0)])
                        StatColumn(title: "", values: ["Red Cards"], isCenter: true)
                        StatColumn(title: "", values: [String(viewModel.awayStatistics.first?.redCard ?? 0)])
                    }
                    
                    StatBar(
                        leftValue: viewModel.homeStatistics.first?.redCard ?? 0,
                        rightValue: viewModel.awayStatistics.first?.redCard ?? 0,
                        leftColor: Color(hex: game.homeTeam.colors?[0] ?? "#FFFFFF"),
                        rightColor: Color(hex: game.awayTeam.colors?[0] ?? "#00C0FF")
                    )
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                    
                    HStack(spacing: 0) {
                        StatColumn(title: "", values: [String(viewModel.homeStatistics.first?.offside ?? 0)])
                        StatColumn(title: "", values: ["Offsides"], isCenter: true)
                        StatColumn(title: "", values: [String(viewModel.awayStatistics.first?.offside ?? 0)])
                    }
                    
                    StatBar(
                        leftValue: viewModel.homeStatistics.first?.offside ?? 0,
                        rightValue: viewModel.awayStatistics.first?.offside ?? 0,
                        leftColor: Color(hex: game.homeTeam.colors?[0] ?? "#FFFFFF"),
                        rightColor: Color(hex: game.awayTeam.colors?[0] ?? "#00C0FF")
                    )
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                    HStack(spacing: 0) {
                        StatColumn(title: "", values: [String(viewModel.homeStatistics.first?.corner ?? 0)])
                        StatColumn(title: "", values: ["Corners"], isCenter: true)
                        StatColumn(title: "", values: [String(viewModel.awayStatistics.first?.corner ?? 0)])
                    }
                    
                    StatBar(
                        leftValue: viewModel.homeStatistics.first?.corner ?? 0,
                        rightValue: viewModel.awayStatistics.first?.corner ?? 0,
                        leftColor: Color(hex: game.homeTeam.colors?[0] ?? "#FFFFFF"),
                        rightColor: Color(hex: game.awayTeam.colors?[0] ?? "#00C0FF")
                    )
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
            }
        }
    }

    /// Creates the background gradient for the game view
    /// - Parameters:
    ///   - homeTeamColor: The home team's color
    ///   - awayTeamColor: The away team's color
    private func gameBackground(homeTeamColor: String, awayTeamColor: String) -> some View {
        Group {
            Rectangle()
                .fill(.thinMaterial)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            HStack(spacing: 0) {
                Rectangle()
                    .fill(Color(hex: homeTeamColor))
                    .opacity(0.4)
                Rectangle()
                    .fill(Color(hex: awayTeamColor))
                    .opacity(0.4)
            }
            .blur(radius: 80)
            LinearGradient(
                gradient: Gradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: Color(.systemBackground).opacity(0.7), location: 0.6),
                        .init(color: Color(.systemBackground).opacity(0.9), location: 1)
                    ]
                ),
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }
}

// MARK: - Supporting Views
/// A view that displays a team's information and score
struct TeamView: View {
    let team: Team
    let score: Int
    
    var body: some View {
        VStack(spacing: 0) {
            Text("\(score)")
                .foregroundStyle(.primary)
                .font(.system(size: 75, weight: .black, design: .default).width(.compressed))
                .contentTransition(.numericText())
                .animation(.default, value: score)
            if let imageUrl = team.image {
                NavigationLink(destination: MyTeamView(team: team)) {  // Update this line
                    AsyncImage(url: URL(string: imageUrl)) { image in
                        image.resizable()
                    } placeholder: {
                        Color.gray.opacity(0.3)
                    }
                    .frame(width: 50, height: 50)
                }
            }
            Text(team.name)
                .font(.system(.footnote, weight: .semibold).width(.condensed))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top,5)
        }
    }
}

/// A scrollable card view for displaying information
struct ScrollableInfoCard<Content: View>: View {
    let title: String
    let icon: String
    let content: () -> Content
    
    init(
        title: String,
        icon: String,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: CardStyle.spacing) {
            HStack(spacing: CardStyle.headerSpacing) {
                Image(systemName: icon)
                    .font(.system(.subheadline, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text(title)
                    .font(.system(.subheadline, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, CardStyle.padding)
            
            content()
        }
        .padding(.vertical, CardStyle.padding)
        .background {
            RoundedRectangle(cornerRadius: CardStyle.cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.03), radius: 3, x: 0, y: 1)
        }
        .padding(.horizontal)
    }
}

/// A view that displays team lineups
struct TeamLineupView: View {
    let team: Team
    let players: [Player]
    let gameId: Int
    
    var body: some View {
        ScrollableInfoCard(title: team.name, icon: "person.3.fill") {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 15) {
                    ForEach(Array(players.enumerated()), id: \.element.id) { index, player in
                        PlayerView(player: player, team: team, gameId: gameId)
                            .padding(.leading, index == 0 ? CardStyle.padding : 0)
                            .padding(.trailing, index == players.count - 1 ? CardStyle.padding : 0)
                    }
                }
            }
        }
    }
}

/// A view that displays player information
struct PlayerView: View {
    let player: Player
    let team: Team
    let gameId: Int  // Add this property
    @State private var isSheetPresented = false
    
    var body: some View {
        VStack {
            AsyncImage(url: URL(string: player.image)) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray.opacity(0.3)
            }
            .frame(width: 70, height: 70)
            .clipShape(Circle())
            .onTapGesture {
                isSheetPresented.toggle()
            }
            
            Text(player.name)
                .font(.caption)
                .lineLimit(1)
            
            Text("#\(player.shirtNumber)")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text(player.position)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(width: 100)
        .sheet(isPresented: $isSheetPresented) {
            NavigationStack {
                PlayerDetailView(playerId: player.id, team: team, gameId: gameId)
            }
        }
    }
}

// MARK: - Helper Views and Functions

/// A view for displaying a timeline event
/// - Parameters:
///  - event: The type of event
///  - description: The description of the event
///  - teamColor: The color of the team
///  - Returns: A view displaying the event
@MainActor private func eventsCard(
    _ game: Game,
    _ viewModel: GameDetailViewModel,
    gameId: Int,
    updateLiveActivityScore: @escaping (Event) -> Void
) -> some View {
    @State var localEvents: [Event] = viewModel.events
    
    return InfoCard(title: "Key Events", icon: "clock.fill") {
        ScrollView {
            HStack(alignment: .top, spacing: 30) {
                VStack(alignment: .leading, spacing: 10) {
                    if localEvents.isEmpty {
                        ContentUnavailableView {
                            Label("No Events", systemImage: "calendar.badge.exclamationmark")
                        } description: {
                            Text("There are no events to display at this time.")
                        }
                    } else {
                        ForEach(localEvents.sorted(by: { $0.id > $1.id })) { event in
                            let teamId = Int(game.homeTeam.id) ?? 0
                            let team = event.team_id == teamId ? game.homeTeam : game.awayTeam
                            TimelineEventView(
                                event: EventType(rawValue: event.event_type) ?? .goal,
                                description: "\(team.name) - \(event.event_type)",
                                teamColor: event.team_colors[0]
                            )
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
    .task {
        await viewModel.startListeningToEvents(gameId: gameId)
    }
    .onDisappear {
        Task {
            await viewModel.stopListeningToEvents()
            print("📊 Stopped listening to events")
        }
    }
    .onChange(of: viewModel.events) { newEvents in
        print("📊 Events updated: \(newEvents.count) events")
        if let latestEvent = newEvents.max(by: { $0.id < $1.id }),
           !localEvents.contains(where: { $0.id == latestEvent.id }) {
            updateLiveActivityScore(latestEvent)
        }
        localEvents = newEvents
    }
}

/// A view that displays Head to Head
/// - Parameters:
///  - game: The current game
///  - viewModel: The view model for the game
///  - Returns: A view displaying the event
private func headToHeadCard(_ game: Game , _ viewModel: GameDetailViewModel) -> some View {
    InfoCard(title: "Head to Head", icon: "arrow.left.and.right") {
        VStack(spacing: CardStyle.spacing) {
            HStack(spacing: 0) {
                VStack(spacing: 4) {
                    Text("\(viewModel.team1Wins)")
                        .font(.system(.title2, weight: .bold))
                        .foregroundStyle(.green)
                    Text(game.homeTeam.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                VStack(spacing: 4) {
                    Text("\(viewModel.draws)")
                        .font(.system(.title2, weight: .bold))
                    Text("Draws")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                VStack(spacing: 4) {
                    Text("\(viewModel.team2Wins)")
                        .font(.system(.title2, weight: .bold))
                        .foregroundStyle(.red)
                    Text(game.awayTeam.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            
            Divider()
            
            if viewModel.team1Score == -1 {
                Text("No previous meetings")
                    .font(.system(.footnote))
                    .foregroundStyle(.secondary)
                } else {
                    Text("Last Meeting: \(viewModel.team1Score)-\(viewModel.team2Score)")
                        .font(.system(.footnote))
                        .foregroundStyle(.secondary)
                }
        }
    }

}

/// A view that displays Form Guide
/// - Parameters:
/// - game: The current game
/// - viewModel: The view model for the game
/// - Returns: A view displaying the event
 func formGuideCard(_ game: Game, _ viewModel: GameDetailViewModel) -> some View {
    InfoCard(title: "Form Guide", icon: "chart.line.uptrend.xyaxis") {
        VStack(spacing: CardStyle.spacing) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(game.homeTeam.name)
                        .font(.system(.footnote, weight: .medium))
                    HStack(spacing: 4) {
                        ForEach(padResults(viewModel.homeLastResults), id: \.self) { result in
                            FormIndicator(result: convertResult(result))
                        }
                    }
                }
                
                Spacer()
                VStack(alignment: .trailing, spacing: 8) {
                    Text(game.awayTeam.name)
                        .font(.system(.footnote, weight: .medium))
                    HStack(spacing: 4) {
                        ForEach(padResults(viewModel.awayLastResults), id: \.self) { result in
                            FormIndicator(result: convertResult(result))
                        }
                    }
                }
            }
        }
    }
}

/// A loading view for additional information
private var loadingAdditionalInfo: some View {
    VStack(alignment: .leading, spacing: 16) {
        Text("Loading Game Information")
            .font(.title3)
            .fontWeight(.bold)
            .padding(.horizontal)
        
        ProgressView()
            .frame(maxWidth: .infinity)
            .padding()
    }
}

// Add these extensions after the GameDetailView struct:
extension String {
    static func convertResult(_ result: String) -> FormResult {
        switch result.lowercased() {
        case "w", "win":
            return .win
        case "l", "loss":
            return .loss
        case "d", "draw":
            return .draw
        default:
            return .empty
        }
    }
}

enum FormResult: String {
    case win = "W"
    case loss = "L"
    case draw = "D"
    case empty = "-"
    
    var color: Color {
        switch self {
        case .win:
            return .green
        case .loss:
            return .red
        case .draw:
            return .orange
        case .empty:
            return .gray.opacity(0.3)
        }
    }
}

/// Pads results array to specified count
/// - Parameters:
///   - results: Array of results to pad
///   - count: Desired final count
/// - Returns: Padded array of results
private func padResults(_ results: [String], count: Int = 5) -> [String] {
    let padding = Array(repeating: "empty", count: max(0, count - results.count))
return Array(results.prefix(count)) + padding
}
