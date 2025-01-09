import SwiftUI

struct PlayerListView: View {
    @StateObject private var viewModel = PlayerViewModel()
    @StateObject private var teamViewModel = TeamsViewModel()
    @State private var searchText = ""
    @State private var selectedPlayer: Player?
    @State private var isShowingDetail = false
    
    var filteredPlayers: [Player] {
        guard !searchText.isEmpty else { return viewModel.players }
        return viewModel.players.filter { player in
            player.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.blue.opacity(0.01)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            Group {
                switch viewModel.state {
                case .loading:
                    ProgressView()
                case .loaded:
                    List(filteredPlayers) { player in
                        Button {
                            selectedPlayer = player
                            Task {
                                await viewModel.fetchPlayerDetail(id: player.id)
                                isShowingDetail = true
                            }
                        } label: {
                            HStack {
                                AsyncImage(url: URL(string: player.image)) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Image(systemName: "person.fill")
                                }
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                                
                                VStack(alignment: .leading) {
                                    Text(player.name)
                                        .font(.headline)
                                    Text("\(player.position) | #\(player.shirtNumber)")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .listRowBackground(Color.primary.opacity(0.1))
                        .foregroundStyle(.primary)
                    }
                    .searchable(text: $searchText, prompt: "Search players")
                    .scrollContentBackground(.hidden)
                case .error(let message):
                    Text(message)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Players")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    withAnimation(.spring()) {
                        viewModel.showFavoritesOnly.toggle()
                    }
                } label: {
                    Image(systemName: viewModel.showFavoritesOnly ? "star.fill" : "star")
                }
            }
        }
        .sheet(isPresented: $isShowingDetail) {
          NavigationStack {
            if let player = selectedPlayer {
                if let team = teamViewModel.team {
                    PlayerDetailView(
                        playerId: player.id,
                        team: team,
                        gameId: nil
                    )
                } else {
                    Text("Loading team info...")
                        .task {
                            await teamViewModel.fetchTeam(teamId: player.club ?? "")
                        }
                }
            }
          }
        }
        .task {
            await viewModel.fetchPlayers()
        }
    }
}
