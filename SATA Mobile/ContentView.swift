//
//  ContentView.swift
//  SATA Mobile
//
//  Created by João Franco on 26/12/2024.
//

import SwiftUI
import SwiftData

enum Tab: String, Hashable {
    case games
    case calendar
    case myTeam
    case profile
    
    var title: String {
        switch self {
        case .games:
            return "Games"
        case .calendar:
            return "Calendar"
        case .myTeam:
            return "My Team"
        case .profile:
            return "Profile"
        }
    }
}

struct ContentView: View {
    @StateObject private var gamesViewModel = GamesViewModel()
    @StateObject private var teamsViewModel = TeamsViewModel()
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    @State private var showOnboarding = false
    
    @State private var selectedTab: Tab = Tab.games
    
    var body: some View {
        GeometryReader { proxy in
            
            ZStack {
                LinearGradient(
                    colors: [.red.opacity(0.8), .red.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                    TabView(selection: $selectedTab) {
                        NavigationStack {
                            GamesView()
                                .navigationTitle("SATA")
                        }
                        .tag(Tab.games)
                        .tabItem {
                            Label("Games", systemImage: "sportscourt.fill")
                        }
                        
                        NavigationStack {
                            CalendarView()
                                .navigationTitle("Calendar")
                        }
                        .tag(Tab.calendar)
                        .tabItem {
                            Label("Calendar", systemImage: "calendar")
                        }
                        
                        NavigationStack {
                            MyTeamView()
                                .navigationTitle(teamsViewModel.currentTeamName ?? "Choose a Team")
                        }
                        .tag(Tab.myTeam)
                        .tabItem {
                            Label("My Team", systemImage: "star.fill")
                        }
                        
                        NavigationStack {
                            ProfileView()
                                .navigationTitle("Profile")
                        }
                        .tag(Tab.profile)
                        .tabItem {
                            Label("Profile", systemImage: "person.circle.fill")
                        }
                    }
                    .navigationTitle("SATA")
                    .tabViewStyle(.sidebarAdaptable)
            }
            .sheet(isPresented: $showOnboarding, onDismiss: {
                hasSeenOnboarding = true
            }) {
                OnboardingView()
                .preferredColorScheme(.dark)
            }
            .onAppear {
                if !hasSeenOnboarding {
                    showOnboarding = true
                }
                
                // Pre-fetch teams data
                Task {
                    await teamsViewModel.fetchTeams()
                    if let storedTeamId = UserDefaults.standard.string(forKey: "teamId"),
                       let storedTeam = teamsViewModel.teams.first(where: { $0.id == storedTeamId }) {
                        teamsViewModel.setTeam(team: storedTeam)
                    }
                }
            }
            .environmentObject(gamesViewModel)
            .environmentObject(teamsViewModel)
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("OpenMyTeamView"))) { _ in
            selectedTab = .myTeam
        }
    }
}

#Preview {
    ContentView()
}
