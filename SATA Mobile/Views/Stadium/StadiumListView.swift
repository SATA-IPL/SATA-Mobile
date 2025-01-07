import SwiftUI

struct StadiumListView: View {
    @StateObject private var viewModel = StadiumsViewModel()
    @State private var showStadiumSheet = false
    @State private var selectedStadium: Stadium?
    @State private var searchText = ""
    
    var filteredStadiums: [Stadium] {
        guard !searchText.isEmpty else { return viewModel.stadiums }
        return viewModel.stadiums.filter { stadium in
            stadium.stadiumName.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                ProgressView()
            case .loaded:
                List(filteredStadiums) { stadium in
                    Button {
                        selectedStadium = stadium
                        showStadiumSheet = true
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
                            
                            Text("\(stadium.stadiumSeats)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .foregroundStyle(.primary)
                }
                .searchable(text: $searchText, prompt: "Search stadiums")
            case .error(let message):
                Text(message)
                    .foregroundStyle(.red)
            }
        }
        .navigationTitle("Stadiums")
        .sheet(isPresented: $showStadiumSheet) {
            if let stadium = selectedStadium {
                StadiumView(stadium: stadium)
            }
        }
        .task {
            await viewModel.fetchStadium()
        }
    }
}
