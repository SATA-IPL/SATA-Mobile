import SwiftUI

struct ProfileView: View {
    @StateObject private var teamsViewModel = TeamsViewModel()
    @State private var showTeamSelection = false
    
    var body: some View {
        List {
            Section("Your Team") {
                Button(action: { showTeamSelection = true }) {
                    HStack {
                        AsyncImage(url: URL(string: teamsViewModel.currentTeamImage ?? "")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } placeholder: {
                            Image(systemName: "photo")
                        }
                        .frame(width: 30, height: 30)
                        .clipShape(Circle())
                        
                        Text(teamsViewModel.currentTeamName ?? "Select a team")
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Section("Account") {
                NavigationLink {
                    Text("Profile Settings")
                } label: {
                    Label("Profile Settings", systemImage: "person.circle")
                }
                
                Button {
                    openAppSettings()
                } label: {
                    Label("System Settings", systemImage: "gear")
                }
            }
            
            Section("Preferences") {
                NavigationLink {
                    Text("Appearance")
                } label: {
                    Label("Appearance", systemImage: "paintbrush")
                }
                
                NavigationLink {
                    Text("Language")
                } label: {
                    Label("Language", systemImage: "globe")
                }
            }
            
            Section("App") {
                NavigationLink {
                    AboutView()
                } label: {
                    Label("About", systemImage: "info.circle")
                }
                
                Button(role: .destructive) {
                    // Handle sign out
                } label: {
                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
        }
        .navigationTitle("Profile")
        .sheet(isPresented: $showTeamSelection) {
            NavigationStack {
                if showTeamSelection {
                    TeamSelectionView()
                    .navigationTitle("Change Team")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Cancel") {
                                showTeamSelection = false
                            }
                        }
                    }
                }
            }
        }
        .task {
            await teamsViewModel.fetchTeams()
        }
    }
    
    func openAppSettings() {
        if let appSettingsURL = URL(string: UIApplication.openSettingsURLString) {
            if UIApplication.shared.canOpenURL(appSettingsURL) {
                UIApplication.shared.open(appSettingsURL, options: [:], completionHandler: nil)
            }
        }
    }
}

#Preview {
    ProfileView()
}
