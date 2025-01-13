import SwiftUI

/// A view that displays detailed information about a team
struct MyTeamView: View {
    // MARK: - Properties
    @StateObject private var viewModel = TeamDetailViewModel() // Add dedicated view model
    @EnvironmentObject private var teamsViewModel: TeamsViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    let team: Team
    
    // MARK: - View State
    enum TeamSection: String, CaseIterable {
        case overview = "Overview"
        case squad = "Squad"
        case matches = "Matches"
    }
    @State private var selectedSection: TeamSection = .overview
    @State private var selectedPlayer: Player?
    @State private var hasLoadedSquad = false
    
    // MARK: - Animation Namespace for iOS 18 Transition
    @Namespace private var animation
    
    // MARK: - Body
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
    
    // MARK: - UI Components
    /// Creates the team header view with logo and name
    /// - Parameter team: The team to display
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
                .padding(.vertical)
            }
        }
    }
    
    // MARK: - Section Views
    /// Overview section showing team statistics and form
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
                        UpcomingGameCard(game: nextGame, teamID: team.id, dateAsHeader: false)
                    }
                } else {
                    Text("No upcoming games")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.top)
    }
    
    /// Squad section showing team players
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
    
    /// Matches section showing upcoming games
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
                        InfoCard(title: game.date + " | " + game.hour, icon: "calendar") {
                            UpcomingGameCard(game: game, teamID: team.id, dateAsHeader: true)
                        }
                    }
                }
            }
        }
        .padding(.top)
    }
    
    // MARK: - Helper Functions
    
    /// Pads results array to specified count
    /// - Parameters:
    ///   - results: Array of results to pad
    ///   - count: Desired final count
    /// - Returns: Padded array of results
    private func padResults(_ results: [String], count: Int = 5) -> [String] {
        let padding = Array(repeating: "empty", count: max(0, count - results.count))
        return Array(results.prefix(count)) + padding
    }
    
    /// Creates the team's background gradient
    /// - Parameter teamColor: The team's primary color
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
