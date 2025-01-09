import SwiftUI

struct MyTeamView: View {
    @StateObject private var viewModel = TeamDetailViewModel() // Add dedicated view model
    @EnvironmentObject private var teamsViewModel: TeamsViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    let team: Team
    
    enum TeamSection: String, CaseIterable {
        case overview = "Overview"
        case squad = "Squad"
        case matches = "Matches"
    }
    @State private var selectedSection: TeamSection = .overview
    @State private var selectedPlayer: Player?
    @State private var hasLoadedSquad = false
    //Animation
    @Namespace private var animation
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Team Header
                    teamHeader(team)
                    
                    // Section Selector
                    CustomSegmentedControl(
                        selectedSection: $selectedSection,
                        sections: TeamSection.allCases
                    )
                    .padding(.vertical, 8)
                    
                    // Content Sections
                    switch selectedSection {
                    case .overview:
                        overviewSection
                    case .squad:
                        squadSection
                    case .matches:
                        matchesSection
                    }
                }
            }
            .background {
                teamBackground(teamColor: team.colors?[0] ?? "#FFFFFF")
            }
            .navigationTitle(team.name)
            .navigationBarTitleDisplayMode(.large)
            .task {
                // Use dedicated view model instead of shared TeamsViewModel
                await viewModel.fetchTeamDetails(teamId: team.id)
                await viewModel.fetchTeamPlayers(team_Id: team.id)
                await viewModel.fetchFormGuide(teamId: Int(team.id) ?? 0)
            }
        }
    }
    
    private func teamHeader(_ team: Team) -> some View {
        VStack(spacing: 16) {
            if let imageUrl = team.image {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(width: 120, height: 120)
                .padding(.top)
            }
            
            VStack(spacing: 4) {
                Text(team.name)
                    .font(.title.bold())
            }
            .padding(.bottom)
        }
    }
    
    private var overviewSection: some View {
        VStack(spacing: 16) {
            // Team Stats Card
            InfoCard(title: "Season Statistics", icon: "chart.bar.fill") {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    StatBox(title: "Matches", value: "\(viewModel.teamStats.matches)")
                    StatBox(title: "Wins", value: "\(viewModel.teamStats.wins)")
                    StatBox(title: "Losses", value: "\(viewModel.teamStats.losses)")
                    StatBox(title: "Goals For", value: "\(viewModel.teamStats.goalsFor)")
                    StatBox(title: "Goals Against", value: "\(viewModel.teamStats.goalsAgainst)")
                    StatBox(title: "Clean Sheets", value: "\(viewModel.teamStats.cleanSheets)")
                }
            }
            
            // Form Guide Card
                InfoCard(title: "Form Guide", icon: "chart.line.uptrend.xyaxis") {
                    VStack(spacing: CardStyle.spacing) {
                        HStack {
                                HStack(spacing: 4) {
                                    ForEach(padResults(viewModel.teamLastResults), id: \.self) { result in
                                        FormIndicator(result: convertResult(result))
                                    }
                            }
                        }
                    }
                }
            
            // Upcoming Games Card
            InfoCard(title: "Upcoming Game", icon: "calendar") {
                if let nextGame = viewModel.upcomingGames.last {
                    NavigationLink {
                        GameDetailView(game: nextGame, gameId: nextGame.id, animation: animation)
                    } label: {
                        UpcomingGameCard(game: nextGame, teamID: team.id)
                    }
                } else {
                    Text("No upcoming games")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.top)
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
    
    private var squadSection: some View {
        VStack {
            if viewModel.squad.isEmpty {
                Text("No players available")
                    .foregroundColor(.secondary)
            } else {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 160, maximum: 180), spacing: 16)
                ], spacing: 16) {
                    ForEach(viewModel.squad) { player in
                        PlayerCard(
                            player: player,
                            teamColor: Color(hex: team.colors?[0] ?? "#000000")
                        )
                        .onTapGesture {
                            selectedPlayer = player
                        }
                    }
                }
            }
        }
        .padding()
        .sheet(item: $selectedPlayer) { player in
            NavigationStack {
                PlayerDetailView(playerId: player.id, team: team, gameId: 0)
            }
            .presentationDetents([.medium])
        }
    }
    
    struct PlayerCard: View {
        let player: Player
        let teamColor: Color
        
        var body: some View {
            VStack(spacing: 12) {
                // Player Image
                ZStack(alignment: .bottomTrailing) {
                    AsyncImage(url: URL(string: player.image)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .foregroundStyle(.gray.opacity(0.3))
                    }
                    .frame(width: 90, height: 90)
                    .clipShape(Circle())
                    .overlay {
                        Circle()
                            .strokeBorder(teamColor, lineWidth: 3)
                    }
                    
                    // Player Number Badge
                    Text("\(player.shirtNumber)")
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(teamColor)
                        .clipShape(Circle())
                        .overlay {
                            Circle()
                                .strokeBorder(.white, lineWidth: 2)
                        }
                        .offset(x: 5, y: 5)
                }
                
                // Player Info
                VStack(spacing: 4) {
                    Text(player.name)
                        .font(.system(size: 16, weight: .semibold))
                        .lineLimit(1)
                        .foregroundStyle(.white)
                    
                    Text(player.position)
                        .font(.system(size: 13, weight: .medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(teamColor.opacity(0.8))
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
                .font(.system(size: 12))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
            }
        }
    }
    
    struct StatItem: View {
        let value: String
        let label: String
        
        var body: some View {
            VStack(spacing: 2) {
                Text(value)
                    .fontWeight(.bold)
                Text(label)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var matchesSection: some View {
        VStack(spacing: 16) {
            if viewModel.upcomingGames.isEmpty {
                ContentUnavailableView {
                    Label("No Matches", systemImage: "sportscourt")
                } description: {
                    Text("Match information will appear here")
                }
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.upcomingGames) { game in
                        UpcomingGameCard(game: game, teamID: team.id)
                    }
                }
            }
        }
        .padding()
    }
    
    private func teamBackground(teamColor: String) -> some View {
        Group {
            Rectangle()
                .fill(.thinMaterial)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            Rectangle()
                .fill(Color(hex: teamColor))
                .opacity(0.4)
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

struct UpcomingGameCard: View {
    let game: Game
    let teamID: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(game.date)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                HStack {
                    Text(game.homeTeam.name)
                        .fontWeight(teamID == String(game.homeTeam.id) ? .bold : .regular)
                    Text("vs")
                        .foregroundStyle(.secondary)
                    Text(game.awayTeam.name)
                        .fontWeight(teamID == String(game.awayTeam.id) ? .bold : .regular)
                }
            }
            Spacer()
            Text(game.hour)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct StatBox: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
