import SwiftUI

struct MyTeamView: View {
    @StateObject private var viewModel = MyTeamViewModel()
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.blue.opacity(0.01)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            if viewModel.games.isEmpty {
                ContentUnavailableView {
                    Label("No Games", systemImage: "star.fill")
                } description: {
                    Text("Check back later for upcoming games")
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        ForEach(viewModel.games) { game in
                            GameCardView(game: game)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
        }
        .task {
            await viewModel.fetchTeamGames()
        }
    }
}
