import SwiftUI

struct CalendarView: View {
    @StateObject private var viewModel = GamesViewModel()
    @State private var selectedDate = Date()
    @State private var showingMonthYear = false
    @State private var monthYearDate = Date()
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return formatter
    }()
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var currentWeek: [Date] = []
    @State private var weeks: [[Date]] = []
    @State private var selectedMonth = Date()
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationSplitView {
            monthView
                .navigationTitle("Calendar")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Today") {
                            withAnimation {
                                selectedMonth = Date()
                                selectedDate = Date()
                                generateWeeks()
                            }
                        }
                    }
                }
        } detail: {
            dayDetailView
                .navigationTitle(selectedDate.formatted(.dateTime.month().day().year()))
        }
        .task {
            generateWeeks()
            await viewModel.fetchGames()
        }
    }
    
    private var monthView: some View {
        VStack(spacing: 1) {
            weekDayHeader
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 1), count: 7), spacing: 1) {
                ForEach(weeks.flatMap { $0 }, id: \.self) { date in
                    DayCell(
                        date: date,
                        isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                        isToday: Calendar.current.isDateInToday(date),
                        isCurrentMonth: Calendar.current.isDate(date, equalTo: selectedMonth, toGranularity: .month),
                        hasGames: hasGames(on: date)
                    )
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3)) {
                            selectedDate = date
                        }
                    }
                }
            }
        }
        .background(colorScheme == .dark ? Color(.systemGray6) : .white)
    }
    
    private var weekDayHeader: some View {
        HStack(spacing: 0) {
            ForEach(Calendar.current.veryShortWeekdaySymbols, id: \.self) { day in
                Text(day)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
        }
        .background(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
    }
    
    private var dayDetailView: some View {
        Group {
            if let gamesForDate = groupedGames[selectedDate.startOfDay] {
                List {
                    ForEach(gamesForDate) { game in
                        HStack(spacing: 15) {
                            Rectangle()
                                .fill(.red)
                                .frame(width: 4)
                                .cornerRadius(2)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(game.parsedDate.formatted(.dateTime.hour().minute()))
                                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                                    .foregroundStyle(.secondary)
                                
                                GameCardView(game: game)
                            }
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 15, bottom: 8, trailing: 15))
                    }
                }
                .listStyle(.insetGrouped)
            } else {
                ContentUnavailableView {
                    Label("No Games", systemImage: "calendar.badge.exclamationmark")
                } description: {
                    Text("There are no games scheduled for \(selectedDate.formatted(.dateTime.month().day()))")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    private func generateWeeks() {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: selectedMonth)
        let year = calendar.component(.year, from: selectedMonth)
        
        guard let monthInterval = calendar.dateInterval(of: .month, for: selectedMonth),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start),
              let monthLastWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.end) else {
            return
        }
        
        var week = monthFirstWeek.start
        weeks.removeAll()
        
        while week <= monthLastWeek.end {
            var weekDates: [Date] = []
            for _ in 0..<7 {
                weekDates.append(week)
                week = calendar.date(byAdding: .day, value: 1, to: week) ?? week
            }
            weeks.append(weekDates)
        }
    }
    
    private func hasGames(on date: Date) -> Bool {
        groupedGames[Calendar.current.startOfDay(for: date)] != nil
    }
    
    private var groupedGames: [Date: [Game]] {
        Dictionary(grouping: viewModel.games) { game in
            // Convert game.date string to Date and get start of day
            if let date = dateFormatter.date(from: game.date) {
                return Calendar.current.startOfDay(for: date)
            }
            return Calendar.current.startOfDay(for: Date())
        }
    }
}

// Helper extension for date comparison
private extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
}

// If needed, update your Game model to handle date parsing
extension Game {
    var parsedDate: Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return formatter.date(from: date) ?? Date()
    }
}

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let isCurrentMonth: Bool
    let hasGames: Bool
    
    var body: some View {
        Text(date.formatted(.dateTime.day()))
            .font(.system(.callout, design: .rounded))
            .fontWeight(isToday ? .bold : .regular)
            .frame(height: 45)
            .frame(maxWidth: .infinity)
            .foregroundStyle(foregroundColor)
            .background {
                if isSelected {
                    Circle()
                        .fill(.red)
                        .padding(8)
                }
                if isToday && !isSelected {
                    Circle()
                        .strokeBorder(.red, lineWidth: 1.5)
                        .padding(8)
                }
            }
            .overlay(alignment: .bottom) {
                if hasGames {
                    Circle()
                        .fill(.red)
                        .frame(width: 5, height: 5)
                        .padding(.bottom, 5)
                }
            }
    }
    
    private var foregroundColor: Color {
        if isSelected {
            return .white
        }
        if !isCurrentMonth {
            return .secondary.opacity(0.5)
        }
        return .primary
    }
}
