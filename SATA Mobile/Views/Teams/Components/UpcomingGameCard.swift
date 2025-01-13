import SwiftUI

/// Card view for displaying upcoming game information
struct UpcomingGameCard: View {
    let game: Game
    let teamID: String
    let dateAsHeader: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                if(!dateAsHeader)
                {
                    Text(game.date + " | " + game.hour)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text(game.homeTeam.name)
                        .fontWeight(teamID == String(game.homeTeam.id) ? .bold : .regular)
                    Text("vs")
                        .foregroundStyle(.secondary)
                    Text(game.awayTeam.name)
                        .fontWeight(teamID == String(game.awayTeam.id) ? .bold : .regular)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .foregroundStyle(.white)
    }
}
