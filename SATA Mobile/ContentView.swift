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
    
    var title: String {
        switch self {
        case .games:
            return "Games"
        case .myTeam:
            return "My Team"
        }
    }
}

struct ContentView: View {
    @StateObject private var viewModel = GamesViewModel()
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
                            MyTeamView()
                                .navigationTitle("Porto")
                        }
                        .tag(Tab.myTeam)
                        .tabItem {
                            Label("My Team", systemImage: "star.fill")
                        }
                    }
                    .navigationTitle("SATA")
                    .tabViewStyle(.sidebarAdaptable)
            }
            .sheet(isPresented: $showOnboarding, onDismiss: {
                hasSeenOnboarding = true
            }) {
                OnboardingView()
            }
            .onAppear {
                if !hasSeenOnboarding {
                    showOnboarding = true
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
