import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var teamsViewModel: TeamsViewModel
    @State private var showTeamSelection = false
    @State private var showOnboarding = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.blue.opacity(0.01)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            List {
                Section("Change Your Team") {
                    Button(action: { showTeamSelection = true }) {
                        HStack {
                            if let imageUrl = teamsViewModel.currentTeamImage {
                                AsyncImage(url: URL(string: imageUrl)) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                } placeholder: {
                                    Image(systemName: "photo")
                                }
                                .frame(width: 30, height: 30)
                            } else {
                                Image(systemName: "star.circle")
                                    .frame(width: 30, height: 30)
                            }
                            
                            Text(teamsViewModel.currentTeamName ?? "Select a team")
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .foregroundColor(.primary)
                }
                .listRowBackground(Color.primary.opacity(0.1))
                
                Section("Account") {
                    Button {
                        openSystemSettings()
                    } label: {
                        Label("System Settings", systemImage: "gear")
                            .foregroundColor(.primary)
                    }
                    
                    Button {
                        openShortcuts()
                    } label: {
                        Label("Shortcuts", systemImage: "arrow.trianglehead.branch")
                            .foregroundColor(.primary)
                    }
                }
                .listRowBackground(Color.primary.opacity(0.1))
                
                Section("App") {
                    NavigationLink {
                        TeamListView()
                    } label: {
                        Label("Teams", systemImage: "shield.lefthalf.filled")
                            .foregroundColor(.primary)
                    }
                    NavigationLink {
                        PlayerListView()
                    } label: {
                        Label("Players", systemImage: "person.fill")
                            .foregroundColor(.primary)
                    }
                    NavigationLink {
                        StadiumListView()
                    } label: {
                        Label("Stadiums", systemImage: "building.2")
                            .foregroundColor(.primary)
                    }
                    
                    Button {
                        showOnboarding = true
                    } label: {
                        Label("App Tour", systemImage: "sparkles")
                            .foregroundColor(.primary)
                    }
                    
                    NavigationLink {
                        AboutView()
                    } label: {
                        Label("About", systemImage: "info.circle")
                            .foregroundColor(.primary)
                    }
                }
                .listRowBackground(Color.primary.opacity(0.1))
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Profile")
        .sheet(isPresented: $showTeamSelection) {
            TeamSelectionView(teamsViewModel: teamsViewModel)
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView()
        }
    }
    
    func openSystemSettings() {
        if let appSettingsURL = URL(string: UIApplication.openSettingsURLString) {
            if UIApplication.shared.canOpenURL(appSettingsURL) {
                UIApplication.shared.open(appSettingsURL, options: [:], completionHandler: nil)
            }
        }
    }
    
    func openShortcuts() {
        if let shortcutsURL = URL(string: "shortcuts://") {
            if UIApplication.shared.canOpenURL(shortcutsURL) {
                UIApplication.shared.open(shortcutsURL, options: [:], completionHandler: nil)
            }
        }
    }
}

#Preview {
    ProfileView()
}
