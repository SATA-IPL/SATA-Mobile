import SwiftUI

/// A view that displays games in both list and calendar formats with filtering capabilities.
struct GamesView: View {
    // MARK: - View Model
    @StateObject private var viewModel = GamesViewModel()
    @EnvironmentObject private var teamsViewModel: TeamsViewModel
    
    // MARK: - View States
    @Namespace private var namespace
    @State private var hasInitiallyFetched = false
    @State private var selectedTeamFilter: Team? = nil
    @State private var isCalendarMode = false
    @State private var selectedMonth: Int = Calendar.current.component(.month, from: Date())
    @Namespace private var monthAnimation
    @State private var isTeamsLoading = true
    @State private var hideOldGames = true

    // MARK: - Body
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
                    HStack {
                        Button {
                            withAnimation {
                                hideOldGames.toggle()
                            }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: {
                            Image(systemName: hideOldGames ? "clock.badge.checkmark.fill" : "clock.badge.xmark.fill")
                                .symbolEffect(.bounce, value: hideOldGames)
                        }
                        
                        viewModeToggle
                            .symbolEffect(.bounce, value: isCalendarMode)
                        
                        teamFilterMenu
                            .symbolEffect(.bounce, value: selectedTeamFilter)
                    }
                }
            }
    }

    // MARK: - Lifecycle Methods
    
    /// Handles the initial data fetch when the view appears.
    private func handleOnAppear() {
        guard !hasInitiallyFetched else { return }
        hasInitiallyFetched = true
        Task { await viewModel.fetchGames() }
    }
    
    // MARK: - Main View Components
    
    /// The main content view that switches between different states.
    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            loadingGamesView
                .transition(.opacity)
        case .error(let message):
            errorView(message: message)
                .transition(.scale.combined(with: .opacity))
        case .loaded where viewModel.games.isEmpty:
            emptyStateView
                .transition(.scale.combined(with: .opacity))
        case .loaded:
            if isCalendarMode {
                calendarView
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            } else {
                gamesList
                    .transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing)))
            }
        }
    }
    
    /// Displays a loading skeleton view while fetching games.
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
    
    /// Displays the list of games with filtering.
    private var gamesList: some View {
        Group {
            if filteredGames.isEmpty {
                filteredEmptyStateView
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 20) {
                        ForEach(filteredGames) { game in
                            GameCardView(game: game)
                                .whenRedacted { $0.hidden() }
                                .matchedGeometryEffect(id: game.id, in: namespace)
                                .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
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

    // MARK: - State Views
    
    /// Displays an error state with retry option.
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
    
    /// Displays when no games are available.
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
    
    /// Displays when filtered results are empty.
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
    
    // MARK: - Navigation and Control Components
    
    /// Menu for filtering games by team.
    private var teamFilterMenu: some View {
        Menu {
            if teamsViewModel.state == .loading {
                Text("Loading teams...")
            } else {
                Button {
                    withAnimation {
                        selectedTeamFilter = nil
                    }
                } label: {
                    HStack {
                        Text("All Teams")
                        if selectedTeamFilter == nil {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                
                if let favoriteTeamId = teamsViewModel.currentTeam,
                   let favoriteTeam = teamsViewModel.teams.first(where: { $0.id == favoriteTeamId }) {
                    Button {
                        withAnimation {
                            selectedTeamFilter = favoriteTeam
                        }
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
                
                if !teamsViewModel.teams.isEmpty {
                    Divider()
                    
                    ForEach(teamsViewModel.teams.sorted(by: { $0.name < $1.name }), id: \.id) { team in
                        Button {
                            withAnimation {
                                selectedTeamFilter = team
                            }
                        } label: {
                            HStack {
                                Text(team.name)
                                if selectedTeamFilter?.id == team.id {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
            }
        } label: {
            Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
        }
    }

    /// Toggle button for switching between list and calendar views.
    private var viewModeToggle: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isCalendarMode.toggle()
            }
        } label: {
            Image(systemName: isCalendarMode ? "list.bullet" : "calendar")
        }
    }

    // MARK: - Calendar View Components
    
    /// Calendar view for displaying games organized by date.
    private var calendarView: some View {
        VStack(spacing: 0) {
            monthPickerView
                .zIndex(1)
            
            ScrollView {
                if hasGamesForSelectedMonth {
                    LazyVStack(spacing: 24, pinnedViews: [.sectionHeaders]) {
                        ForEach(groupedGames.keys.sorted(), id: \.self) { date in
                            if let games = groupedGames[date],
                               let monthFromDate = Int(date.split(separator: "-")[1]),
                               monthFromDate == selectedMonth {
                                Section {
                                    ForEach(games) { game in
                                        GameCardView(game: game)
                                            .padding(.horizontal)
                                            .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
                                            .transition(.scale.combined(with: .opacity))
                                    }
                                } header: {
                                    Text(formatDate(date))
                                        .font(.headline)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding()
                                        .background(.ultraThinMaterial)
                                }
                            }
                        }
                    }
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 70))
                            .foregroundStyle(.secondary)
                            .symbolEffect(.bounce, options: .repeat(2))
                        
                        Text("No Games Scheduled")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("There are no games scheduled for \(DateFormatter().monthSymbols[selectedMonth-1])")
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 60)
                    .frame(maxWidth: .infinity)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .refreshable {
                await viewModel.fetchGames()
            }
        }
    }

    /// Month selection picker for calendar view.
    private var monthPickerView: some View {
        ScrollViewReader { proxy in
            VStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(1...12, id: \.self) { month in
                            VStack(spacing: 8) {
                                Text(DateFormatter().monthSymbols[month-1])
                                    .fontWeight(selectedMonth == month ? .bold : .regular)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                ZStack {
                                    if selectedMonth == month {
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(Color.accentColor)
                                            .matchedGeometryEffect(id: "monthBackground", in: monthAnimation)
                                    }
                                }
                            )
                            .padding(.vertical, 12)
                            .foregroundColor(selectedMonth == month ? .white : .primary)
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
                }
                
                Divider()
                    .background(Color.gray.opacity(0.2))
            }
            .background(.ultraThinMaterial)
        }
    }

    // MARK: - Helper Properties
    
    /// Returns filtered games based on selected team and hide old games toggle.
    private var filteredGames: [Game] {
        var games = viewModel.games
        
        if hideOldGames {
            let today = Calendar.current.startOfDay(for: Date())
            games = games.filter { game in
                if let gameDate = DateFormatter.yyyyMMdd.date(from: game.date) {
                    return Calendar.current.startOfDay(for: gameDate) >= today
                }
                return true
            }
        }
        
        if let selectedTeam = selectedTeamFilter {
            games = games.filter { game in
                game.homeTeam.id == selectedTeam.id || game.awayTeam.id == selectedTeam.id
            }
        }
        
        return games.sorted { $0.date < $1.date }
    }

    /// Groups games by date for calendar view.
    @MainActor
    private var groupedGames: [String: [Game]] {
        Dictionary(grouping: filteredGames) { game in
            game.date
        }
    }

    /// Checks if there are games scheduled for the selected month.
    private var hasGamesForSelectedMonth: Bool {
        groupedGames.keys.contains { date in
            if let monthFromDate = Int(date.split(separator: "-")[1]) {
                return monthFromDate == selectedMonth
            }
            return false
        }
    }

    // MARK: - Utility Methods
    
    /// Formats a date string into a readable format.
    /// - Parameter dateString: Date string in "yyyy-MM-dd" format
    /// - Returns: Formatted date string
    private func formatDate(_ dateString: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        guard let date = dateFormatter.date(from: dateString) else { return dateString }
        
        dateFormatter.dateFormat = "EEEE, MMMM d"
        return dateFormatter.string(from: date)
    }
}

// MARK: - DateFormatter Extension

extension DateFormatter {
    /// Formatter for "yyyy-MM-dd" date format
    static let yyyyMMdd: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
