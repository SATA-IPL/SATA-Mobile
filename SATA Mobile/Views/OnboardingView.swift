//
//  OnboardingSheet.swift
//  SATA Mobile
//
//  Created by João Franco on 27/12/2024.
//

import SwiftUI

struct FeatureRow: View {
    let systemImage: String
    let title: String
    let description: String
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 16) {
                Image(systemName: systemImage)
                    .font(.system(size: 32))
                    .foregroundColor(.accentColor)
                    .frame(width: geometry.size.width * 0.2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(width: geometry.size.width * 0.7)
            }
            .frame(maxWidth: .infinity)
        }
        .frame(height: 60)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var teamsViewModel = TeamsViewModel()
    @State private var currentPage = 0
    
    var body: some View {
        TabView(selection: $currentPage) {
            WelcomeView(showLogo: true, showTitle: true, showFeatures: true)
                .tag(0)
            
            TeamSelectionView(
                teamsViewModel: teamsViewModel,
                onComplete: {
                    //Set
                    dismiss()
                }
            )
            .tag(1)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .background {
            AnimatedColorsMeshGradientView()
                .blur(radius: 60)
                .ignoresSafeArea()
        }
        .task {
            await teamsViewModel.fetchTeams()
        }
    }
}

struct WelcomeView: View {
    @State var showLogo: Bool = false
    @State var showTitle: Bool = false
    @State var showFeatures: Bool = false
    
    var body: some View {
        VStack {
            Spacer()
            Image(systemName: "soccerball")
                .renderingMode(.original)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 75)
                .padding(.top, 20)
                .padding(.bottom, 20)
                .offset(y: showLogo ? 0 : -50)
                .opacity(showLogo ? 1 : 0)
            
            Text("Welcome to SATA")
                .font(.system(.largeTitle, weight: .bold))
                .frame(maxWidth: .infinity)
                .clipped()
                .multilineTextAlignment(.center)
                .padding(.bottom, 52)
                .offset(y: showTitle ? 0 : 30)
                .opacity(showTitle ? 1 : 0)
            
            VStack(spacing: 16) {
                FeatureRow(
                    systemImage: "gamecontroller.fill",
                    title: "Play Games",
                    description: "Enjoy our selection of interactive games"
                )
                
                FeatureRow(
                    systemImage: "person.2.fill",
                    title: "Connect with Friends",
                    description: "Challenge others and compete for high scores"
                )
                
                FeatureRow(
                    systemImage: "trophy.fill",
                    title: "Earn Rewards",
                    description: "Collect points and unlock achievements"
                )
            }
            .padding(.bottom, 32)
            .offset(y: showFeatures ? 0 : 50)
            .opacity(showFeatures ? 1 : 0)
            
            Spacer()
            Text("Swipe to continue")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 29)
        .padding(.vertical)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                showLogo = true
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                showTitle = true
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.4)) {
                showFeatures = true
            }
        }
    }
}

struct TeamSelectionView: View {
    @ObservedObject var teamsViewModel: TeamsViewModel
    let onComplete: () -> Void
    @State private var showContent = false
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Choose Your Team")
                .font(.title.bold())
                .padding(.top)
            
            Text("Select the team you want to follow")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            switch teamsViewModel.state {
            case .loading:
                Spacer()
                ProgressView()
                Spacer()
            case .loaded:
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(teamsViewModel.teams, id: \.id) { team in
                            teamButton(for: team)
                        }
                    }
                    .padding(.vertical)
                }
                .scrollIndicators(.hidden)
            case .error(let message):
                Text(message)
                    .foregroundColor(.red)
            }
            
            Button(action: onComplete) {
                Text("Get Started")
                    .font(.system(.callout, weight: .semibold))
                    .padding()
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.accentColor)
                    .background(.accent.opacity(0.1))
                    .mask(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .padding()
        }
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 50)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                showContent = true
            }
        }
    }
    
    private func teamButton(for team: Team) -> some View {
        Button(action: {
            teamsViewModel.SetTeam(team: team)
        }) {
            HStack(spacing: 16) {
                AsyncImage(url: URL(string: team.image ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    Image(systemName: "photo")
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
                .overlay {
                    Circle()
                        .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                }
                
                Text(team.name)
                    .font(.headline)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
    }
}
