import SwiftUI

struct GamesView: View {
    @StateObject private var viewModel = GamesViewModel()
    @Namespace private var namespace
    @State private var hasInitiallyFetched = false
    
    var body: some View {
            Group { content }
                .onAppear(perform: handleOnAppear)
                .navigationTitle("Games")
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.accent.opacity(0.2), Color.accent.opacity(0.01)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                )
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
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                ForEach(viewModel.games) { game in
                    GameCardView(game: game)
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
            Label("No Games", systemImage: "sportscourt")
        } description: {
            Text("Check back later for upcoming games")
        }
    }
}
