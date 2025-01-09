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
    case myTeam
    case profile
    
    var title: String {
        switch self {
        case .games:
            return "Games"
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
    @StateObject private var stadiumsViewModel = StadiumsViewModel()
    @StateObject private var playerViewModel = PlayerViewModel()
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    @State private var showOnboarding = false
    @State private var showTeamSelection = false
    
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
                                .navigationTitle("Games")
                        }
                        .tag(Tab.games)
                        .tabItem {
                            Label("Games", systemImage: "sportscourt.fill")
                        }
                        
                        NavigationStack {
                            switch teamsViewModel.state {
                            case .loading:
                                ProgressView("Loading team...")
                                    .navigationTitle("My Team")
                            case .loaded:
                                if let team = teamsViewModel.team {
                                    MyTeamView(team: team)
                                } else {
                                    ZStack {
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.blue.opacity(0.01)]),
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                        .ignoresSafeArea()
                                        ContentUnavailableView {
                                            Label("No Team Selected", systemImage: "star.slash")
                                        } description: {
                                            Text("Select your favorite team to see their stats and upcoming games")
                                        } actions: {
                                            Button(action: { showTeamSelection = true }) {
                                                Text("Choose Team")
                                                    .fontWeight(.bold)
                                            }
                                            .buttonStyle(.borderedProminent)
                                        }
                                    }
                                    .navigationTitle("Choose Team")
                                }
                            case .error(let message):
                                ContentUnavailableView {
                                    Label("Unable to Load Team", systemImage: "exclamationmark.triangle")
                                } description: {
                                    Text(message)
                                } actions: {
                                    Button(action: {
                                        Task {
                                            await teamsViewModel.fetchTeams()
                                        }
                                    }) {
                                        Text("Try Again")
                                            .fontWeight(.bold)
                                    }
                                    .buttonStyle(.borderedProminent)
                                }
                                .navigationTitle("Error")
                            }
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
            .sheet(isPresented: $showTeamSelection) {
                TeamSelectionView(teamsViewModel: teamsViewModel)
            }
            .onAppear {
                if !hasSeenOnboarding {
                    showOnboarding = true
                }
                
                // Pre-fetch teams and games data
                Task {
                    await teamsViewModel.fetchTeams()
                    await gamesViewModel.fetchGames()
                    
                    if let storedTeamId = UserDefaults.standard.string(forKey: "teamId"),
                       let storedTeam = teamsViewModel.teams.first(where: { $0.id == storedTeamId }) {
                        teamsViewModel.setTeam(team: storedTeam)
                    }
                }
            }
            .environmentObject(gamesViewModel)
            .environmentObject(teamsViewModel)
            .environmentObject(stadiumsViewModel)
            .environmentObject(playerViewModel)
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("OpenMyTeamView"))) { _ in
            selectedTab = .myTeam
        }
    }
}

#Preview {
    ContentView()
}
