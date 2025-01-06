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
                Button {
                    openAppSettings()
                } label: {
                    Label("System Settings", systemImage: "gear")
                }
            }
        
            
            Section("App") {
                NavigationLink {
                    AboutView()
                } label: {
                    Label("About", systemImage: "info.circle")
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
