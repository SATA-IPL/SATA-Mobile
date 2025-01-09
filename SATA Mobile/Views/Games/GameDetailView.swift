import SwiftUI
import AVKit
import GoogleGenerativeAI
import ActivityKit

struct GameDetailView: View {
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
    @State private var isLoading = true // Add this property
    @State private var timer: Timer?
    
    
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
    
    private func stopLiveActivity() {
        Task {
            await activity?.end(nil, dismissalPolicy: .immediate)
        }
    }

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

    // Add this helper function
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

    private func startGameTimeUpdates() {
        timer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
            if let detailedGame = viewModel.game {
                updateLiveActivityTime(game: detailedGame)
            }
        }
    }
    
    private func stopGameTimeUpdates() {
        timer?.invalidate()
        timer = nil
    }
    
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

    enum GameSection: String, CaseIterable {
        case overview = "Overview"
        case analysis = "Analysis"
        case lineups = "Lineups"
    }
    
    @State private var selectedSection: GameSection = .overview
    
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
                                    Image(systemName: "star.fill")
                                        .opacity(detailedGame.homeScore > detailedGame.awayScore ? 1 : 0)
                                        .frame(maxWidth: .infinity)
                                    Spacer()
                                    HStack {
                                        VStack {
                                            Text(detailedGame.hour)
                                                .font(.system(.title2, weight: .bold).width(.compressed))
                                            let formattedDate = detailedGame.date.components(separatedBy: "-").reversed().joined(separator: "/")
                                            Text(formattedDate)
                                                .font(.system(.headline, weight: .bold).width(.compressed))
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    Image(systemName: "star.fill")
                                        .opacity(detailedGame.awayScore > detailedGame.homeScore ? 1 : 0)
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
    
    private func additionalGameInfo(_ detailedGame: Game) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            SoccerFieldView(homeTeam: detailedGame.homeTeam, awayTeam: detailedGame.awayTeam, gameId: gameId)
                .frame(height: 300)
                .padding(.horizontal)
            
            Text("Squads")
                .font(.title3)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            if let players = detailedGame.homeTeam.players {
                TeamLineupView(team: detailedGame.homeTeam, players: players, gameId: gameId)
            }
            
            if let players = detailedGame.awayTeam.players {
                TeamLineupView(team: detailedGame.awayTeam, players: players, gameId: gameId)
            }
        }
    }
    
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

// Add this new card variant
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

// Add this enum for consistent styling
enum CardStyle {
    static let padding: CGFloat = 16
    static let cornerRadius: CGFloat = 16
    static let spacing: CGFloat = 12
    static let headerSpacing: CGFloat = 8
}

// Updated InfoCard with refined styling
struct InfoCard<Content: View>: View {
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
            
            content()
        }
        .padding(CardStyle.padding)
        .background {
            RoundedRectangle(cornerRadius: CardStyle.cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.03), radius: 3, x: 0, y: 1)
        }
        .padding(.horizontal)
    }
}

// Updated StatColumn with refined styling
struct StatColumn: View {
    let title: String
    let values: [String]
    let isCenter: Bool
    let teamColor: Color?
    let showBar: Bool
    let isLeftTeam: Bool
    
    init(
        title: String,
        values: [String],
        isCenter: Bool = false,
        teamColor: Color? = nil,
        showBar: Bool = false,
        isLeftTeam: Bool = true
    ) {
        self.title = title
        self.values = values
        self.isCenter = isCenter
        self.teamColor = teamColor
        self.showBar = showBar
        self.isLeftTeam = isLeftTeam

        print("StatColumn initialized with values: \(values)")
    }
    
    private func percentageFromString(_ string: String) -> Double {
        if let value = Double(string.replacingOccurrences(of: "%", with: "")) {
            return value / 100.0
        }
        return 0
    }
    
    var body: some View {
        VStack(spacing: 8) {
            if (!title.isEmpty) {
                Text(title)
                    .font(.system(.caption, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            
            ForEach(Array(values.enumerated()), id: \.offset) { index, value in
                VStack(spacing: 4) {
                    Text(value)
                        .font(.system(.callout, weight: isCenter ? .regular : .semibold))
                        .monospacedDigit()
                    
                    if showBar && teamColor != nil {
                        GeometryReader { geometry in
                            let percentage = percentageFromString(value)
                            let width = geometry.size.width * percentage
                            
                            ZStack(alignment: isLeftTeam ? .leading : .trailing) {
                                Capsule()
                                    .fill(.secondary.opacity(0.2))
                                    .frame(height: 3)
                                
                                Capsule()
                                    .fill(teamColor ?? .clear)
                                    .frame(width: width, height: 3)
                            }
                        }
                        .frame(height: 3)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(isCenter ? .center : .leading)
    }
}

struct StatBar: View {
    let leftValue: Int
    let rightValue: Int
    let leftColor: Color
    let rightColor: Color
    
    private var leftPercentage: CGFloat {
        let total = CGFloat(leftValue + rightValue)
        return total > 0 ? CGFloat(leftValue) / total : 0.5
    }
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                Rectangle()
                    .fill(leftColor)
                    .frame(width: geometry.size.width * leftPercentage)
                
                Rectangle()
                    .fill(rightColor)
                    .frame(width: geometry.size.width * (1 - leftPercentage))
            }
            .frame(height: 4)
            .clipShape(Capsule())
        }
        .frame(height: 4)
    }
}

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

// Add this new component for form indicators
struct FormIndicator: View {
    let result: String
    
    var backgroundColor: Color {
        switch result {
        case "W": return .green.opacity(0.8)
        case "L": return .red.opacity(0.8)
        case "D": return .orange.opacity(0.8)
        case "empty": return .gray.opacity(0.2) // Placeholder color
        default: return .gray.opacity(0.8)
        }
    }
    
    var body: some View {
        Text(result == "empty" ? "" : result)
            .font(.system(.caption2, weight: .black))
            .foregroundColor(.white)
            .frame(width: 20, height: 20)
            .background(backgroundColor)
            .clipShape(Circle())
    }
}

// Modify eventsCard to include game parameter
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
                    Text("Match Timeline")
                        .font(.title2.bold())
                    
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


// Modify headToHeadCard to include game parameter
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

// Modify formGuideCard to include game parameter
private func formGuideCard(_ game: Game, _ viewModel: GameDetailViewModel) -> some View {
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
private func convertResult(_ result: String) -> String {
    print("🔄 Converting result: \(result)")
    let converted = switch result.lowercased() {
        case "win": "W"
        case "draw": "D"
        case "loss": "L"
        default: "-"
    }
    print("✅ Converted to: \(converted)")
    return converted
}
private func padResults(_ results: [String], count: Int = 5) -> [String] {
    let padding = Array(repeating: "empty", count: max(0, count - results.count))
    return Array(results.prefix(count)) + padding
}

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
