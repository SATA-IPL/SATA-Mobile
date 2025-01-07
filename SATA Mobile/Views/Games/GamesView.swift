import SwiftUI

struct GamesView: View {
    @StateObject private var viewModel = GamesViewModel()
    @StateObject private var teamsViewModel = TeamsViewModel()
    @Namespace private var namespace
    @State private var hasInitiallyFetched = false
    @State private var selectedTeamFilter: Team? = nil
    
    var body: some View {
            Group { content }
                .onAppear(perform: handleOnAppear)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.accent.opacity(0.2), Color.accent.opacity(0.01)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                )
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        teamFilterMenu
                    }
                }
    }
    
    // MARK: - Private Methods
    
    private func handleOnAppear() {
        guard !hasInitiallyFetched else { return }
        hasInitiallyFetched = true
        Task { await viewModel.fetchGames() }
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            loadingGamesView
        case .error(let message):
            errorView(message: message)
        case .loaded where viewModel.games.isEmpty:
            emptyStateView
        case .loaded:
            gamesList
        }
    }
    
    private var loadingGamesView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                ForEach(0..<3) { _ in
                    LoadingGameSection()
                }
            }
            .padding(.vertical)
        }
        .background(.clear)
    }
    
    private var gamesList: some View {
        Group {
            if filteredGames.isEmpty {
                filteredEmptyStateView
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        ForEach(filteredGames) { game in
                            GameCardView(game: game)
                                .whenRedacted { $0.hidden() }
                                .matchedGeometryEffect(id: game.id, in: namespace)
                        }
                    }
                    .padding()
                }
                .background(.clear)
                .refreshable {
                    await viewModel.fetchGames()
                }
            }
        }
    }

    private var filteredGames: [Game] {
        guard let selectedTeam = selectedTeamFilter else {
            return viewModel.games
        }
        return viewModel.games.filter { game in
            game.homeTeam.id == selectedTeam.id || game.awayTeam.id == selectedTeam.id
        }
    }
    
    private func errorView(message: String) -> some View {
        ContentUnavailableView {
            Label("Unable to Load Games", systemImage: "wifi.slash")
        } description: {
            Text(message)
        } actions: {
            Button("Try Again") {
                Task { @MainActor in
                    await viewModel.fetchGames()
                }
            }
            .buttonStyle(.bordered)
        }
    }
    
    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Games Scheduled", systemImage: "sportscourt")
        } description: {
            Text("There are currently no games scheduled.\nCheck back later for upcoming matches.")
        } actions: {
            Button("Refresh") {
                Task { @MainActor in
                    await viewModel.fetchGames()
                }
            }
            .buttonStyle(.bordered)
        }
    }
    
    private var filteredEmptyStateView: some View {
        ContentUnavailableView {
            Label("No Games Found", systemImage: "magnifyingglass")
        } description: {
            if let team = selectedTeamFilter {
                Text("There are no games scheduled for \(team.name).\nTry selecting a different team.")
            } else {
                Text("No games match your current filter.\nTry adjusting your selection.")
            }
        } actions: {
            Button("Clear Filter") {
                selectedTeamFilter = nil
            }
            .buttonStyle(.bordered)
        }
    }
    
    private var teamFilterMenu: some View {
        Menu {
            Button {
                selectedTeamFilter = nil
            } label: {
                HStack {
                    Text("All Teams")
                    if selectedTeamFilter == nil {
                        Image(systemName: "checkmark")
                    }
                }
            }
            
            if let favoriteTeamId = UserDefaults.standard.string(forKey: "teamId"),
               let favoriteTeam = teamsViewModel.teams.first(where: { $0.id == favoriteTeamId }) {
                Button {
                    selectedTeamFilter = favoriteTeam
                } label: {
                    HStack {
                        Text(favoriteTeam.name)
                        Image(systemName: "star.fill")
                        if selectedTeamFilter?.id == favoriteTeam.id {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
            
            Divider()
            
            ForEach(teamsViewModel.teams.sorted(by: { $0.name < $1.name }), id: \.id) { team in
                Button {
                    selectedTeamFilter = team
                } label: {
                    HStack {
                        Text(team.name)
                        if selectedTeamFilter?.id == team.id {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
        }
        .onAppear {
            Task {
                await teamsViewModel.fetchTeams()
            }
        }
    }
}
