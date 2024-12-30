import SwiftUI

struct TeamsRowView: View {
    let teams: [Team]
    let selectedTeam: Team?
    let onTeamSelect: (Team) -> Void
    
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

private struct TeamItemView: View {
    let team: Team
    let isSelected: Bool
    let onTap: () -> Void
    
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
