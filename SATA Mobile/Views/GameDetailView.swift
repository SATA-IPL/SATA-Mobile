import SwiftUI
import AVKit

struct GameDetailView: View {
    let game: Game
    let gameId: Int
    @StateObject private var viewModel = GameDetailViewModel()
    var animation: Namespace.ID
    @State private var showStadium = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Reuse existing game data immediately
                    HStack(spacing: 0) {
                        TeamView(team: game.homeTeam, score: game.homeScore)
                        Image(systemName: "star.fill")
                            .opacity(game.homeScore > game.awayScore ? 1 : 0)
                            .frame(maxWidth: .infinity)
                        Spacer()
                        HStack {
                            VStack {
                                Text("02:10")
                                    .font(.system(.title2, weight: .bold).width(.compressed))
                                Text("28/12/2024")
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
                    
                    PillButton(
                        action: { },
                        title: "Watch on SATA+",
                        icon: "play.circle.fill"
                    )
                    
                    // Show loading state only for additional details
                    switch viewModel.state {
                    case .loading:
                        loadingAdditionalInfo
                    case .error(let message):
                        ContentUnavailableView {
                            Label("Unable to Load Details", systemImage: "exclamationmark.triangle")
                        } description: {
                            Text(message)
                        } actions: {
                            Button("Try Again") {
                                Task { await viewModel.fetchGameDetail(id: gameId) }
                            }
                            .buttonStyle(.bordered)
                        }
                    case .loaded:
                        if let detailedGame = viewModel.game {
                            additionalGameInfo(detailedGame)
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
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.fetchGameDetail(id: gameId)
            if let game = viewModel.game {
                print("Fetched game details:", game)
            }
        }
        .toolbarVisibility(
                        .hidden, for: .tabBar)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
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
    }
    
    private var loadingAdditionalInfo: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Lineups")
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
            Text("Lineups")
                .font(.title3)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            if let players = detailedGame.homeTeam.players {
                TeamLineupView(team: detailedGame.homeTeam, players: players)
            }
            
            if let players = detailedGame.awayTeam.players {
                TeamLineupView(team: detailedGame.awayTeam, players: players)
            }
        }
    }
    
    private func gameBackground(homeTeamColor: String, awayTeamColor: String) -> some View {
        Group {
            Rectangle()
                .fill(.thinMaterial)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            LinearGradient(
                colors: [Color.init(hex: homeTeamColor), Color.init(hex: awayTeamColor)],
                startPoint: .leading,
                endPoint: .trailing
            )
            .opacity(0.5)
            .blur(radius: 100)
            LinearGradient(gradient: Gradient(colors: [.clear, Color(.systemBackground)]), startPoint: .top, endPoint: .bottom)
        }
        .ignoresSafeArea()
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
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

struct TeamLineupView: View {
    let team: Team
    let players: [Player]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(team.name)
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 15) {
                    ForEach(players) { player in
                        PlayerView(player: player, team: team)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct PlayerView: View {
    let player: Player
    @State private var isSheetPresented = false
    
    let team: Team
    
    
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
                PlayerDetailView(playerId: player.id, team: team)
            }
        }
    }
}
