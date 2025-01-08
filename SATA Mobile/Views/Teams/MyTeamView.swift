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
            InfoCard(title: "Recent Form", icon: "chart.line.uptrend.xyaxis") {
                HStack(spacing: 8) {
                    ForEach(viewModel.recentForm, id: \.self) { result in
                        FormIndicator(result: result)
                    }
                    Spacer()
                }
            }
            
            // Next Match Card
            if let nextMatch = viewModel.nextMatch {
                InfoCard(title: "Next Match", icon: "calendar") {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(nextMatch.opponent)
                                .font(.headline)
                            Text(nextMatch.date)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(nextMatch.competition)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
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
                        EnhancedPlayerCard(
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
        }
    }

    struct EnhancedPlayerCard: View {
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
            if viewModel.matches.isEmpty {
                ContentUnavailableView {
                    Label("No Matches", systemImage: "sportscourt")
                } description: {
                    Text("Match information will appear here")
                }
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.matches) { match in
                        MatchRow(match: match)
                    }
                }
            }
        }
        .padding()
    }

    struct MatchRow: View {
        let match: Match
        
        var body: some View {
            HStack {
                // Result indicator
                Circle()
                    .fill(resultColor)
                    .frame(width: 8, height: 8)
                
                // Date
                Text(match.date)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(width: 80, alignment: .leading)
                
                // Match details
                VStack(alignment: .leading, spacing: 4) {
                    Text(match.opponent)
                        .font(.headline)
                    Text(match.competition)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Score
                Text(match.score)
                    .font(.headline)
                    .monospacedDigit()
            }
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.background)
                    .shadow(color: .black.opacity(0.05), radius: 3, y: 2)
            }
        }
        
        private var resultColor: Color {
            switch match.result.lowercased() {
            case "w": return .green
            case "l": return .red
            default: return .yellow
            }
        }
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
