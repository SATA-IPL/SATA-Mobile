import SwiftUI

struct CalendarView: View {
    @EnvironmentObject private var gamesViewModel: GamesViewModel
    @State private var selectedMonth: Int = Calendar.current.component(.month, from: Date())
    @State private var scrollViewOffset: CGFloat = 0
    @Namespace private var monthAnimation
    
    var groupedGames: [String: [Game]] {
        Dictionary(grouping: gamesViewModel.games) { game in
            game.date
        }
    }
    
    var hasGamesForSelectedMonth: Bool {
        groupedGames.keys.contains { date in
            if let monthFromDate = Int(date.split(separator: "-")[1]) {
                return monthFromDate == selectedMonth
            }
            return false
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
            
            VStack(spacing: 0) {
                // Month picker with sticky header
                monthPickerView
                    .zIndex(1)
                
                ScrollView {
                    VStack(spacing: 20) {
                        GeometryReader { geometry in
                            Color.clear
                        }
                        .frame(height: 0)
                        
                        if hasGamesForSelectedMonth {
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
                        } else {
                            VStack(spacing: 20) {
                                Image(systemName: "calendar.badge.exclamationmark")
                                    .font(.system(size: 70))
                                    .foregroundStyle(.secondary)
                                
                                Text("No Games Scheduled")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text("There are no games scheduled for \(DateFormatter().monthSymbols[selectedMonth-1])")
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.top, 60)
                        }
                    }
                    .padding(.top, 20)
                }
                .coordinateSpace(name: "scroll")
            }
        }
        .onAppear {
            scrollToCurrentMonth()
        }
    }
    
    private var monthPickerView: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(1...12, id: \.self) { month in
                        Text(DateFormatter().monthSymbols[month-1])
                            .fontWeight(selectedMonth == month ? .bold : .regular)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(selectedMonth == month ? 
                                          Color.accentColor : Color.gray.opacity(0.1))
                            )
                            .foregroundColor(selectedMonth == month ? .white : .primary)
                            .matchedGeometryEffect(
                                id: month,
                                in: monthAnimation,
                                isSource: selectedMonth == month
                            )
                            .id(month)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedMonth = month
                                    proxy.scrollTo(month, anchor: .center)
                                }
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
        }
    }
    
    private func scrollToCurrentMonth() {
        withAnimation {
            selectedMonth = Calendar.current.component(.month, from: Date())
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
