import SwiftUI

struct MyTeamView: View {
    let team: Team
    @EnvironmentObject private var viewModel: TeamsViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    enum TeamSection: String, CaseIterable {
        case overview = "Overview"
        case squad = "Squad"
        case matches = "Matches"
    }
    @State private var selectedSection: TeamSection = .overview
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    if let team = viewModel.team {
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
                    } else {
                        ContentUnavailableView {
                            Label("Select Your Team", systemImage: "star.fill")
                        } description: {
                            Text("Choose your favorite team to see their stats and updates")
                        } actions: {
                            Button(action: { /* Team selection action */ }) {
                                Text("Select Team")
                                    .fontWeight(.semibold)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .frame(maxHeight: .infinity)
                        .frame(minHeight: UIScreen.main.bounds.height * 0.7)
                    }
                }
            }
            .background {
                if let team = viewModel.team {
                    teamBackground(teamColor: team.colors?[0] ?? "#FFFFFF")
                } else {
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.blue.opacity(0.01)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                }
            }
            .navigationTitle("My Team")
            .navigationBarTitleDisplayMode(.large)
            .task {
                await viewModel.fetchTeamDetails()
                await viewModel.fetchTeamPlayers(team_Id: viewModel.team?.id ?? "")
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
         if viewModel.state == .loading {
             ProgressView()
         } else if viewModel.squad.isEmpty {
             Text("No players available")
                 .foregroundColor(.secondary)
         } else {
             LazyVGrid(columns: [
                 GridItem(.flexible()),
                 GridItem(.flexible())
             ], spacing: 16) {
                 ForEach(viewModel.squad) { player in
                     NavigationLink(destination: PlayerDetailView(playerId: player.id, team: team, gameId: 0)) {
                         PlayerCard(player: player)
                     }
                 }
             }
         }
     }
     .padding()
 }
    
    private var matchesSection: some View {
        VStack(spacing: 16) {
            ForEach(viewModel.matches) { match in
                MatchRow(match: match)
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
