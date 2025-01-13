import SwiftUI

struct GameCardView: View {
    let game: Game
    @Namespace var animation

    var body: some View {
        NavigationLink {
            GameDetailView(
                game: game,
                gameId: game.id,
                animation: animation
            )
        } label: {
            VStack(alignment: .leading) {
                gameImage
            }
            .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(.thinMaterial, lineWidth: 2)
        )
        }
        .buttonBorderShape(.roundedRectangle(radius: 20))
        .buttonStyle(.plain)
        .matchedTransitionSource(id: game.id, in: animation)
    }

    private var gameImage: some View {
        HStack(spacing: 0) {
            ZStack {
                Rectangle()
                    .fill(.black)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                Rectangle()
                    .fill(.thinMaterial)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                LinearGradient(
                    colors: [Color.init(hex: game.homeTeam.colors?[0] ?? "#FFFFFF"), Color.init(hex: game.awayTeam.colors?[0] ?? "#00C0FF")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .opacity(0.5)
                .blur(radius: 50)

                HStack(spacing: 20) {
                    VStack{
                        if let imageUrl = game.homeTeam.image {
                            AsyncImage(url: URL(string: imageUrl)) { image in
                                image.resizable()
                            } placeholder: {
                                Color.gray.opacity(0.3)
                            }
                            .frame(width: 50, height: 50)
                        }
                        Text(game.homeTeam.name)
                            .font(.system(.footnote, weight: .semibold).width(.condensed))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .clipped()
                    Text("\(game.homeScore)")
                            .foregroundStyle(.primary)
                            .font(.system(size: 50, weight: .black, design: .default).width(.compressed))
                    HStack {
                        
                        VStack {
                            Text(game.hour)
                                .font(.system(.title2, weight: .bold).width(.compressed))
                            let formattedDate = game.date.components(separatedBy: "-").reversed().joined(separator: "/")
                            Text(formattedDate)
                                .font(.system(.headline, weight: .bold).width(.compressed))
                                .foregroundStyle(.secondary)
                        }
                        
                    }
                    .frame(maxWidth: .infinity)
                    .clipped()
                    Text("\(game.awayScore)")
                        .foregroundStyle(.primary)
                        .font(.system(size: 50, weight: .black, design: .default).width(.compressed))
                    
                    VStack{
                        if let imageUrl = game.awayTeam.image {
                            AsyncImage(url: URL(string: imageUrl)) { image in
                                image.resizable()
                            } placeholder: {
                                Color.gray.opacity(0.3)
                            }
                            .frame(width: 50, height: 50)
                        }
                        Text(game.awayTeam.name)
                            .font(.system(.footnote, weight: .semibold).width(.condensed))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .clipped()
                }
                .padding()
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 85)
        .clipped()
        .mask { RoundedRectangle(cornerRadius: 20, style: .continuous) }
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 3)
    }
}

