import SwiftUI

/// A horizontal scrollable view that displays a list of teams
struct TeamsRowView: View {
    // MARK: - Properties
    /// Array of teams to display
    let teams: [Team]
    /// Currently selected team
    let selectedTeam: Team?
    /// Callback triggered when a team is selected
    let onTeamSelect: (Team) -> Void
    
    // MARK: - Body
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(teams) { team in
                    TeamItemView(
                        team: team,
                        isSelected: selectedTeam?.id == team.id,
                        onTap: { onTeamSelect(team) }
                    )
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - TeamItemView
/// A view representing a single team item with an image and name
private struct TeamItemView: View {
    // MARK: - Properties
    /// Team to display
    let team: Team
    /// Whether this team is currently selected
    let isSelected: Bool
    /// Callback triggered when the team is tapped
    let onTap: () -> Void
    
    // MARK: - Body
    var body: some View {
        VStack {
            AsyncImage(url: URL(string: team.image ?? "")) { image in
                image
                    .resizable()
                    .scaledToFit()
            } placeholder: {
                ProgressView()
            }
            .frame(width: 60, height: 60)
            .background(Color(.systemBackground))
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(isSelected ? Color.accentColor : Color.gray.opacity(0.2), 
                           lineWidth: 2)
            )
            
            Text(team.name)
                .font(.caption)
                .lineLimit(1)
        }
        .frame(width: 80)
        .onTapGesture(perform: onTap)
    }
}
