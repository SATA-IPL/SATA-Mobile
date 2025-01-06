import SwiftUI
import AVKit
import GoogleGenerativeAI
import ActivityKit

struct GameDetailView: View {
    let game: Game
    let gameId: Int
    @StateObject private var viewModel = GameDetailViewModel()
    var animation: Namespace.ID
    @State private var showStadium = false
    @State private var showVideoPlayer = false
    
    //Gemini
    static let config = GenerationConfig(
        temperature: 1,
        topP: 0.95,
        topK: 40,
        maxOutputTokens: 8192,
        responseMIMEType: "text/plain"
    )
    
    let model = GenerativeModel(
        name: "gemini-2.0-flash-exp",
        apiKey: APIKey.default,
        generationConfig: Self.config
    )
    @State var userPrompt = ""
    @State var response: LocalizedStringKey = "How can I help you today?"
    @State var isLoading = false
    @State private var isTextExpanded = false
    @State private var showChat = false
    @State private var messageText = ""
    @State private var isListening = false
    @State private var animationScale: CGFloat = 1.0
    @State private var activity: Activity<GameActivityAttributes>?
    
    func generateResponse(){
        isLoading = true;
        response = ""
        
        Task {
            do {
                let result = try await model.generateContent(userPrompt)
                isLoading = false
                response = LocalizedStringKey(result.text ?? "No response found")
                userPrompt = ""
            } catch {
                response = "Something went wrong! \n\(error.localizedDescription)"
            }
        }
    }
    
    private func startLiveActivity() {
        Task {
            
            let attributes = GameActivityAttributes(
                homeTeam: game.homeTeam.name,
                awayTeam: game.awayTeam.name,
                homeTeamColor: game.homeTeam.colors?[0] ?? "#FFFFFF",
                awayTeamColor: game.awayTeam.colors?[0] ?? "#00C0FF"
            )
            
            let contentState = GameActivityAttributes.ContentState(
                homeScore: game.homeScore,
                awayScore: game.awayScore,
                gameStatus: game.state,
                gameTime: "90",
                lastEvent: "Goal"
            )
            
            activity = try? Activity<GameActivityAttributes>.request(
                attributes: attributes,
                contentState: contentState,
                pushType: nil
            )
        }
    }
    
    private func stopLiveActivity() {
        Task {
            await activity?.end(nil, dismissalPolicy: .immediate)
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
            ScrollView{
                VStack(spacing: 0) {
                    // Game header with teams and score
                    HStack(spacing: 0) {
                        TeamView(team: game.homeTeam, score: game.homeScore)
                        Image(systemName: "star.fill")
                            .opacity(game.homeScore > game.awayScore ? 1 : 0)
                            .frame(maxWidth: .infinity)
                        Spacer()
                        HStack {
                            VStack {
                                Text(game.hour)
                                    .font(.system(.title2, weight: .bold).width(.compressed))
                                let formattedDate = game.date.components(separatedBy: "-").reversed().joined(separator: "/")
                                Text(formattedDate)
                                    .font(.system(.headline, weight: .bold).width(.compressed))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        Image(systemName: "star.fill")
                            .opacity(game.awayScore > game.homeScore ? 1 : 0)
                            .frame(maxWidth: .infinity)
                        TeamView(team: game.awayTeam, score: game.awayScore)
                    }
                    .padding(.horizontal, 35)
                    AddToShortcutsButton()
                    if(game.state == "live" || game.state == "finished"){
                        PillButton(
                            action: { showVideoPlayer.toggle() },
                            title: "Watch on SATA+",
                            icon: "play.circle.fill"
                        )
                        .padding(.top, 10)
                    }
                    
                    
                    // Replace old Picker with new custom control
                    CustomSegmentedControl(selectedSection: $selectedSection)
                        .padding(.vertical, 8)
                    
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
        .fullScreenCover(isPresented: $showVideoPlayer) {
            VideoPlayerView(videoURL: URL(string: game.videoUrl!)!, title: "Title", subtitle: "Subtitle")
                .presentationBackground(.clear)
                .ignoresSafeArea()
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.fetchGameDetail(id: gameId)
            if let game = viewModel.game {
                //print("Fetched game details:", game)
                // Start live activity for demo purposes, regardless of game state
                startLiveActivity()
            }
        }
        .onDisappear {
            stopLiveActivity()
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
                StadiumView(stadium: stadium)
            }
        }
        .fullScreenCover(isPresented: $showChat) {
            ChatView(game: game, model: model, isPresented: $showChat)
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
                    
                    matchStatsCard(game)
                    eventsCard(game)
                }
            }
        }
    }
    
    private var analysisSection: some View {
        VStack(spacing: 20) {
            // Existing analysis card
            VStack(alignment: .leading) {
                HStack {
                    Text("Game Analysis")
                        .font(.title3)
                        .fontWeight(.bold)
                    Spacer()
                    Label("AI Generated", systemImage: "sparkles")
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                
                ZStack {
                    if isLoading {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(0..<3) { _ in
                                ShimmerLoadingView()
                                    .frame(height: 16)
                                    .cornerRadius(8)
                            }
                        }
                        .padding()
                    } else {
                        Text(response)
                            .font(.body)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(.thinMaterial)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
            }
            .onAppear {
                if response == "How can I help you today?" {
                    userPrompt = "Write a brief, engaging historical highlight about past matches between \(game.homeTeam.name) and \(game.awayTeam.name) with interesting facts for a description card. Just include response text. No Title"
                    generateResponse()
                }
            }
            
            headToHeadCard(game)
            formGuideCard(game)
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
    
    private var loadingAdditionalInfo: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Loading Game Information")
                .font(.title3)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            ForEach(0..<2) { _ in
                VStack(alignment: .leading, spacing: 10) {
                    ShimmerLoadingView()
                        .frame(width: 120, height: 20)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 15) {
                            ForEach(0..<5) { _ in
                                VStack {
                                    ShimmerLoadingView()
                                        .frame(width: 70, height: 70)
                                        .clipShape(Circle())
                                    ShimmerLoadingView()
                                        .frame(width: 60, height: 12)
                                }
                                .frame(width: 100)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
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

struct CustomSegmentedControl: View {
    @Binding var selectedSection: GameDetailView.GameSection
    let sections = GameDetailView.GameSection.allCases
    
    var body: some View {
        HStack {
            ForEach(sections, id: \.self) { section in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedSection = section
                    }
                }) {
                    Text(section.rawValue)
                        .font(.system(.title2, weight: .bold).width(.compressed))
                        .clipped()
                        .foregroundStyle(selectedSection == section ? .primary : .secondary)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal)
        .padding(.vertical)
    }
}

struct TeamView: View {
    let team: Team
    let score: Int
    
    var body: some View {
        VStack(spacing:0) {
            Text("\(score)")
                .foregroundStyle(.primary)
                .font(.system(size: 75, weight: .black, design: .default).width(.compressed))
            if let imageUrl = team.image {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image.resizable()
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(width: 50, height: 50)
            }
            Text(team.name)
                .font(.system(.footnote, weight: .semibold).width(.condensed))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top,5)
        }
    }
}

struct TeamLineupView: View {
    let team: Team
    let players: [Player]
    let gameId: Int  // Add this property
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(team.name)
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 15) {
                    ForEach(players) { player in
                        PlayerView(player: player, team: team, gameId: gameId)
                    }
                }
                .padding(.horizontal)
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

// 1. Cache field background pattern to avoid recreating it on every render
class FieldBackgroundModel: ObservableObject {
    let fieldPattern: some View = GeometryReader { geo in
        Path { path in
            let stripeWidth: CGFloat = 30
            for x in stride(from: 0, through: geo.size.width, by: stripeWidth) {
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: geo.size.height))
            }
        }
        .stroke(Color.white.opacity(0.05), lineWidth: 15)
    }
}

// 2. Pre-calculate and cache player positions to avoid recalculation on every render
struct SoccerFieldView: View {
    let homeTeam: Team
    let awayTeam: Team
    let gameId: Int
    @StateObject private var backgroundModel = FieldBackgroundModel()
    @State private var playerPositions: [String: CGPoint] = [:]
    
    // Calculate positions once and cache them
    private func calculatePositions(in size: CGSize) {
        guard playerPositions.isEmpty else { return } // Only calculate once
        
        let basePositions: [(CGFloat, CGFloat)] = [
            (0.95, 0.5), (0.85, 0.20), (0.85, 0.4), (0.85, 0.6), (0.85, 0.80),
            (0.70, 0.30), (0.70, 0.5), (0.70, 0.70), (0.60, 0.15), (0.58, 0.5), (0.60, 0.85)
        ]
        
        let width = size.width
        let height = size.height
        let dotTotalHeight: CGFloat = -10
        let yOffset = dotTotalHeight / 2
        
        // Pre-calculate all positions
        for (index, position) in basePositions.enumerated() {
            // Home team positions
            let homeX = (1.0 - position.0) * width
            let homeY = position.1 * height - yOffset
            playerPositions["home_\(index)"] = CGPoint(x: homeX, y: homeY)
            
            // Away team positions
            let awayX = position.0 * width
            let awayY = position.1 * height - yOffset
            playerPositions["away_\(index)"] = CGPoint(x: awayX, y: awayY)
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Simplified background without shader
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "#1A472A"), Color(hex: "#2E8B57")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .opacity(0.8)
                    }
                    .overlay {
                        backgroundModel.fieldPattern
                    }
                
                // Enhanced field lines with glow effect
                SoccerFieldLines()
                    .opacity(0.7)
                    .drawingGroup()
                    .shadow(color: .white.opacity(0.3), radius: 2, x: 0, y: 0)
                
                // Player layer with enhanced shadows
                PlayersLayer(
                    homePlayers: homeTeam.players?.prefix(11).enumerated().map { ($0, $1) } ?? [],
                    awayPlayers: awayTeam.players?.prefix(11).enumerated().map { ($0, $1) } ?? [],
                    positions: playerPositions,
                    homeColor: Color(hex: homeTeam.colors?[0] ?? "#FFFFFF"),
                    awayColor: Color(hex: awayTeam.colors?[0] ?? "#00C0FF"),
                    homeTeam: homeTeam,
                    awayTeam: awayTeam,
                    gameId: gameId
                )
                .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            .drawingGroup()
            .onAppear {
                calculatePositions(in: geometry.size)
            }
            .onChange(of: geometry.size) { newSize in
                calculatePositions(in: newSize)
            }
        }
    }
}

// 8. Separate player rendering into its own component for better optimization
struct PlayersLayer: View {
    let homePlayers: [(Int, Player)]
    let awayPlayers: [(Int, Player)]
    let positions: [String: CGPoint]
    let homeColor: Color
    let awayColor: Color
    let homeTeam: Team
    let awayTeam: Team
    let gameId: Int
    
    var body: some View {
        ZStack {
            // Home team players
            ForEach(homePlayers, id: \.1.id) { index, player in
                if let position = positions["home_\(index)"] {
                    PlayerDot(player: player, teamColor: homeColor, team: homeTeam, gameId: gameId)
                        .position(position)
                }
            }
            
            // Away team players
            ForEach(awayPlayers, id: \.1.id) { index, player in
                if let position = positions["away_\(index)"] {
                    PlayerDot(player: player, teamColor: awayColor, team: awayTeam, gameId: gameId)
                        .position(position)
                }
            }
        }
    }
}

// 9. Use Canvas for field lines instead of complex Shape paths
struct SoccerFieldLines: View {
    var body: some View {
        Canvas { context, size in
            let lineColor = Color.white
            
            // Outline
            context.stroke(
                Path { path in
                    path.addRect(CGRect(origin: .zero, size: size))
                },
                with: .color(lineColor),
                lineWidth: 2
            )
            
            // Center line
            context.stroke(
                Path { path in
                    path.move(to: CGPoint(x: size.width/2, y: 0))
                    path.addLine(to: CGPoint(x: size.width/2, y: size.height))
                },
                with: .color(lineColor),
                lineWidth: 2
            )
            
            // Center circle
            context.stroke(
                Circle().path(in: CGRect(x: size.width/2 - size.height/6,
                                         y: size.height/2 - size.height/6,
                                         width: size.height/3,
                                         height: size.height/3)),
                with: .color(lineColor),
                lineWidth: 2
            )
            
            // Center dot
            context.fill(
                Circle().path(in: CGRect(x: size.width/2 - 4,
                                         y: size.height/2 - 4,
                                         width: 8,
                                         height: 8)),
                with: .color(lineColor)
            )
            
            let penaltyAreaWidth = size.width * 0.16
            let penaltyAreaHeight = size.height * 0.4
            
            // Corner arcs
            let cornerRadius: CGFloat = size.height * 0.04
            for (x, y) in [(0, 0), (size.width, 0), (0, size.height), (size.width, size.height)] {
                context.stroke(
                    Path { path in
                        path.addArc(
                            center: CGPoint(x: x, y: y),
                            radius: cornerRadius,
                            startAngle: Angle(degrees: x == 0 ? (y == 0 ? 0 : -90) : (y == 0 ? 90 : 180)),
                            endAngle: Angle(degrees: x == 0 ? (y == 0 ? 90 : 0) : (y == 0 ? 180 : 270)),
                            clockwise: false
                        )
                    },
                    with: .color(lineColor),
                    lineWidth: 2
                )
            }
            
            // Penalty areas
            for isLeft in [true, false] {
                let x = isLeft ? 0 : size.width - penaltyAreaWidth
                let penaltyAreaY = (size.height - penaltyAreaHeight) / 2
                
                // Main penalty box
                context.stroke(
                    Path { path in
                        path.addRect(CGRect(x: x,
                                            y: penaltyAreaY,
                                            width: penaltyAreaWidth,
                                            height: penaltyAreaHeight))
                    },
                    with: .color(lineColor),
                    lineWidth: 2
                )
                
                // Goal box - smaller proportions
                let goalBoxWidth = penaltyAreaWidth * 0.35
                let goalBoxHeight = penaltyAreaHeight * 0.4
                let goalBoxX = isLeft ? 0 : size.width - goalBoxWidth
                let goalBoxY = (size.height - goalBoxHeight) / 2
                context.stroke(
                    Path { path in
                        path.addRect(CGRect(x: goalBoxX,
                                            y: goalBoxY,
                                            width: goalBoxWidth,
                                            height: goalBoxHeight))
                    },
                    with: .color(lineColor),
                    lineWidth: 2
                )
                
                // Penalty spot at correct FIFA distance
                let penaltySpotX = isLeft ? (penaltyAreaWidth * 0.75) : (size.width - penaltyAreaWidth * 0.75)
                let penaltySpotY = size.height * 0.5
                
                // Arc that matches FIFA specifications
                let arcRadius = penaltyAreaWidth * 0.5  // Radius based on box width instead of height
                
                if isLeft {
                    // Left penalty arc - exactly touching penalty box
                    context.stroke(
                        Path { path in
                            path.addArc(
                                center: CGPoint(x: penaltySpotX, y: penaltySpotY),
                                radius: arcRadius,
                                startAngle: Angle(degrees: -50),
                                endAngle: Angle(degrees: 50),
                                clockwise: false
                            )
                        },
                        with: .color(lineColor),
                        lineWidth: 2
                    )
                } else {
                    // Right penalty arc - exactly touching penalty box
                    context.stroke(
                        Path { path in
                            path.addArc(
                                center: CGPoint(x: penaltySpotX, y: penaltySpotY),
                                radius: arcRadius,
                                startAngle: Angle(degrees: 130),
                                endAngle: Angle(degrees: 230),
                                clockwise: false
                            )
                        },
                        with: .color(lineColor),
                        lineWidth: 2
                    )
                }
                
                // Penalty spot
                context.fill(
                    Circle().path(in: CGRect(
                        x: penaltySpotX - 3,
                        y: penaltySpotY - 3,
                        width: 6,
                        height: 6
                    )),
                    with: .color(lineColor)
                )
            }
        }
    }
}

struct PlayerDot: View {
    let player: Player
    let teamColor: Color
    let team: Team
    let gameId: Int  // Add optional gameId parameter
    @State private var isSheetPresented = false
    
    var body: some View {
        VStack(spacing: 2) {
            Circle()
                .fill(.ultraThinMaterial)
                .overlay {
                    Circle()
                        .fill(teamColor)
                        .padding(1)
                        .shadow(color: teamColor.opacity(0.5), radius: 2, x: 0, y: 0)
                }
                .overlay {
                    Text(player.shirtNumber)
                        .font(.system(size: 12, weight: .black))
                        .foregroundColor(teamColor.textColor())
                }
                .frame(width: 26, height: 26)
                .onTapGesture {
                    isSheetPresented.toggle()
                }
            
            Text(player.name.split(separator: " ").last ?? "")
                .font(.system(size: 8, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background {
                    Capsule()
                        .fill(.black.opacity(0.6))
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                }
        }
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
    let isLoading: Bool
    let content: () -> Content
    
    init(
        title: String,
        icon: String,
        isLoading: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.isLoading = isLoading
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
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                }
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
    }
    
    private func percentageFromString(_ string: String) -> Double {
        if let value = Double(string.replacingOccurrences(of: "%", with: "")) {
            return value / 100.0
        }
        return 0
    }
    
    var body: some View {
        VStack(spacing: 8) {
            if !title.isEmpty {
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

private func matchStatsCard(_ game: Game) -> some View {
    InfoCard(title: "Match Stats", icon: "chart.bar.fill") {
        VStack(spacing: CardStyle.spacing) {
            HStack(spacing: 0) {
                StatColumn(title: game.homeTeam.name, values: ["12"])
                StatColumn(title: "", values: ["Shots"], isCenter: true)
                StatColumn(title: game.awayTeam.name, values: ["9"])
            }
            
            StatBar(
                leftValue: 12,
                rightValue: 9,
                leftColor: Color(hex: game.homeTeam.colors?[0] ?? "#FFFFFF"),
                rightColor: Color(hex: game.awayTeam.colors?[0] ?? "#00C0FF")
            )
            .padding(.horizontal)
            .padding(.bottom, 8)
            
            // Add more stats with their respective bars...
            Group {
                HStack(spacing: 0) {
                    StatColumn(title: "", values: ["8"])
                    StatColumn(title: "", values: ["Corners"], isCenter: true)
                    StatColumn(title: "", values: ["4"])
                }
                
                StatBar(
                    leftValue: 8,
                    rightValue: 4,
                    leftColor: Color(hex: game.homeTeam.colors?[0] ?? "#FFFFFF"),
                    rightColor: Color(hex: game.awayTeam.colors?[0] ?? "#00C0FF")
                )
                .padding(.horizontal)
                .padding(.bottom, 8)
                
                HStack(spacing: 0) {
                    StatColumn(title: "", values: ["55%"])
                    StatColumn(title: "", values: ["Possession"], isCenter: true)
                    StatColumn(title: "", values: ["45%"])
                }
                
                StatBar(
                    leftValue: 55,
                    rightValue: 45,
                    leftColor: Color(hex: game.homeTeam.colors?[0] ?? "#FFFFFF"),
                    rightColor: Color(hex: game.awayTeam.colors?[0] ?? "#00C0FF")
                )
                .padding(.horizontal)
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
        default: return .orange.opacity(0.8)
        }
    }
    
    var body: some View {
        Text(result)
            .font(.system(.caption2, weight: .black))
            .foregroundColor(.white)
            .frame(width: 20, height: 20)
            .background(backgroundColor)
            .clipShape(Circle())
    }
}

// Modify eventsCard to include game parameter
private func eventsCard(_ game: Game) -> some View {
    InfoCard(title: "Key Events", icon: "clock.fill") {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(["45' Goal - João Félix", "67' Yellow Card - Nuno Tavares", "89' Substitution"], id: \.self) { event in
                HStack(alignment: .center, spacing: 12) {
                    Circle()
                        .fill(.secondary.opacity(0.2))
                        .frame(width: 6, height: 6)
                    Text(event)
                        .font(.system(.subheadline))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

// Modify headToHeadCard to include game parameter
private func headToHeadCard(_ game: Game) -> some View {
    InfoCard(title: "Head to Head", icon: "arrow.left.and.right") {
        VStack(spacing: CardStyle.spacing) {
            HStack(spacing: 0) {
                VStack(spacing: 4) {
                    Text("15")
                        .font(.system(.title2, weight: .bold))
                        .foregroundStyle(.green)
                    Text("Wins")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                VStack(spacing: 4) {
                    Text("7")
                        .font(.system(.title2, weight: .bold))
                    Text("Draws")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                VStack(spacing: 4) {
                    Text("12")
                        .font(.system(.title2, weight: .bold))
                        .foregroundStyle(.red)
                    Text("Losses")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            
            Divider()
            
            Text("Last Meeting: 2-1")
                .font(.system(.footnote))
                .foregroundStyle(.secondary)
        }
    }
}

// Modify formGuideCard to include game parameter
private func formGuideCard(_ game: Game) -> some View {
    InfoCard(title: "Form Guide", icon: "chart.line.uptrend.xyaxis") {
        VStack(spacing: CardStyle.spacing) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(game.homeTeam.name)
                        .font(.system(.footnote, weight: .medium))
                    HStack(spacing: 4) {
                        ForEach(["W", "L", "W", "W", "D"], id: \.self) { result in
                            FormIndicator(result: result)
                        }
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    Text(game.awayTeam.name)
                        .font(.system(.footnote, weight: .medium))
                    HStack(spacing: 4) {
                        ForEach(["L", "W", "D", "W", "W"], id: \.self) { result in
                            FormIndicator(result: result)
                        }
                    }
                }
            }
        }
    }
}
