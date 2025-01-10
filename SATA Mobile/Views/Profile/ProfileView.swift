import SwiftUI

/// A view that displays user profile settings and navigation options
/// This view allows users to:
/// - Change their current team
/// - Access system settings
/// - Navigate to different sections of the app
/// - View app information
struct ProfileView: View {
    // MARK: - Properties
    @EnvironmentObject private var teamsViewModel: TeamsViewModel
    @State private var showTeamSelection = false
    @State private var showOnboarding = false
    
    // MARK: - View Body
    var body: some View {
        ZStack {
            // MARK: Background Gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.blue.opacity(0.01)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // MARK: Main Content
            List {
                // MARK: Team Selection Section
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
                
                // MARK: Account Settings Section
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
                
                // MARK: App Navigation Section
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
    
    // MARK: - Helper Methods
    
    /// Opens the system settings app
    private func openSystemSettings() {
        if let appSettingsURL = URL(string: UIApplication.openSettingsURLString) {
            if UIApplication.shared.canOpenURL(appSettingsURL) {
                UIApplication.shared.open(appSettingsURL, options: [:], completionHandler: nil)
            }
        }
    }
    
    /// Opens the Shortcuts app
    private func openShortcuts() {
        if let shortcutsURL = URL(string: "shortcuts://") {
            if UIApplication.shared.canOpenURL(shortcutsURL) {
                UIApplication.shared.open(shortcutsURL, options: [:], completionHandler: nil)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ProfileView()
}
