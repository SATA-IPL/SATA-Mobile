import SwiftUI

/// A view that displays a searchable list of stadiums with filtering capabilities
/// and navigation to detailed stadium views.
struct StadiumListView: View {
    // MARK: - Properties
    
    @EnvironmentObject private var stadiumsViewModel: StadiumsViewModel
    @State private var selectedStadium: Stadium?
    @State private var searchText = ""
    
    // MARK: - Computed Properties
    
    /// Returns a filtered array of stadiums based on search text and favorites filter
    var filteredStadiums: [Stadium] {
        let favoriteFiltered = stadiumsViewModel.filteredStadiums
        guard !searchText.isEmpty else { return favoriteFiltered }
        return favoriteFiltered.filter { stadium in
            stadium.stadiumName.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.blue.opacity(0.01)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // MARK: - Content
            
            Group {
                switch stadiumsViewModel.state {
                case .loading:
                    ProgressView()
                case .loaded:
                    List(filteredStadiums) { stadium in
                        // Stadium row button
                        Button {
                            selectedStadium = stadium
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(stadium.stadiumName)
                                        .font(.headline)
                                    Text("Built in \(stadium.yearBuilt)")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                //Chevron
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .listRowBackground(Color.primary.opacity(0.1))
                        .foregroundStyle(.primary)
                    }
                    .searchable(text: $searchText, prompt: "Search stadiums")
                    .scrollContentBackground(.hidden)
                case .error(let message):
                    Text(message)
                        .foregroundStyle(.red)
                }
            }
        }
        // MARK: - View Modifiers
        
        .navigationTitle("Stadiums")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                // Favorites toggle button
                Button {
                    withAnimation(.spring()) {
                        stadiumsViewModel.showFavoritesOnly.toggle()
                    }
                } label: {
                    Image(systemName: stadiumsViewModel.showFavoritesOnly ? "star.fill" : "star")
                }
            }
        }
        .sheet(item: $selectedStadium) { stadium in
            StadiumView(viewModel: stadiumsViewModel, stadium: stadium)
        }
        .task {
            await stadiumsViewModel.fetchStadiums()
        }
    }
}
