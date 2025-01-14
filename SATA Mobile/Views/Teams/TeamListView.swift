import SwiftUI

/// A view that displays a list of teams with search functionality
struct TeamListView: View {
    // MARK: - Properties
    @EnvironmentObject private var teamsViewModel: TeamsViewModel
    @State private var searchText = ""
    
    /// Filtered teams based on search text
    /// Returns all teams if search text is empty, otherwise returns teams matching the search criteria
    var filteredTeams: [Team] {
        guard !searchText.isEmpty else { return teamsViewModel.teams }
        return teamsViewModel.teams.filter { team in
            team.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    // MARK: - View Body
    var body: some View {
        // Background gradient
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.blue.opacity(0.01)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // MARK: - Content
            Group {
                switch teamsViewModel.state {
                case .loading:
                    ProgressView()
                case .loaded:
                    // Team list with search functionality
                    List(filteredTeams) { team in
                        NavigationLink(destination: MyTeamView(team: team)) {
                            HStack {
                                if let imageUrl = team.image {
                                    AsyncImage(url: URL(string: imageUrl)) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                    } placeholder: {
                                        Image(systemName: "photo")
                                    }
                                    .frame(width: 30, height: 30)
                                } else {
                                    Image(systemName: "star.circle")
                                        .frame(width: 30, height: 30)
                                }
                                
                                VStack(alignment: .leading) {
                                    Text(team.name)
                                        .font(.headline)
                                }
                                
                                Spacer()
                            }
                        }
                        .listRowBackground(Color.primary.opacity(0.1))
                        .foregroundStyle(.primary)
                    }
                    .searchable(text: $searchText, prompt: "Search teams")
                    .scrollContentBackground(.hidden)
                case .error(let message):
                    // Error view with retry action
                    ContentUnavailableView {
                        Label("Unable to Load Team", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(message)
                    } actions: {
                        Button("Retry", action: {
                            Task {
                                await teamsViewModel.fetchTeams()
                            }
                        })
                    }
                }
            }
        }
        .navigationTitle("Teams")
    }
}
