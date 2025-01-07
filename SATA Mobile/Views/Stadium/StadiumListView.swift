import SwiftUI

struct StadiumListView: View {
    @StateObject private var viewModel = StadiumsViewModel()
    @State private var selectedStadium: Stadium?
    @State private var searchText = ""
    
    var filteredStadiums: [Stadium] {
        guard !searchText.isEmpty else { return viewModel.stadiums }
        return viewModel.stadiums.filter { stadium in
            stadium.stadiumName.localizedCaseInsensitiveContains(searchText)
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
                    List(filteredStadiums) { stadium in
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
        .navigationTitle("Stadiums")
        .sheet(item: $selectedStadium) { stadium in
            StadiumView(stadium: stadium)
        }
        .task {
            await viewModel.fetchStadium()
        }
    }
}
