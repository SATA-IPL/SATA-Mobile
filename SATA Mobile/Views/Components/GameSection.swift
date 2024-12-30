import SwiftUI

struct GameSection: View {
    let games: [Game]
    let namespace: Namespace.ID
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            LazyVStack(spacing: 16) {
                ForEach(games) { game in
                    GameCardView(game: game)
                }
            }
            .padding(.horizontal)
        }
    }
}
