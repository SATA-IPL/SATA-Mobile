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
    case profile
    
    var title: String {
        switch self {
        case .games:
            return "Games"
        case .profile:
            return "Profile"
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
                NavigationStack {
                    TabView(selection: $selectedTab) {
                        GamesView()
                            .tag(Tab.games)
                            .tabItem {
                                Label("Games", systemImage: "play.tv")
                            }
                        
                        NavigationStack {
                            ProfileView()
                                .tag(Tab.profile)
                        }
                        .tabItem {
                            Label("Profile", systemImage: "person.circle.fill")
                        }
                    }
                    .navigationTitle(selectedTab.title)
                    .tabViewStyle(.sidebarAdaptable)
                }
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
