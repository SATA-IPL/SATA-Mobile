import SwiftUI

struct CalendarView: View {
    @EnvironmentObject private var gamesViewModel: GamesViewModel
    @State private var selectedMonth: Int = Calendar.current.component(.month, from: Date())
    
    var groupedGames: [String: [Game]] {
        Dictionary(grouping: gamesViewModel.games) { game in
            game.date
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Month picker
                Picker("Month", selection: $selectedMonth) {
                    ForEach(1...12, id: \.self) { month in
                        Text(DateFormatter().monthSymbols[month-1])
                            .tag(month)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Games list grouped by date
                LazyVStack(spacing: 15) {
                    ForEach(groupedGames.keys.sorted(), id: \.self) { date in
                        if let games = groupedGames[date],
                           let monthFromDate = Int(date.split(separator: "-")[1]),
                           monthFromDate == selectedMonth {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(formatDate(date))
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                ForEach(games) { game in
                                    GameCardView(game: game)
                                        .padding(.horizontal)
                                }
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            if gamesViewModel.games.isEmpty {
                Task {
                    await gamesViewModel.fetchGames()
                }
            }
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        guard let date = dateFormatter.date(from: dateString) else { return dateString }
        
        dateFormatter.dateFormat = "EEEE, MMMM d"
        return dateFormatter.string(from: date)
    }
}