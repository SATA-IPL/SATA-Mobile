import SwiftUI

/// Card view for displaying player information
struct PlayerCard: View {
    let player: Player
    let teamColor: Color
    
    var body: some View {
        VStack(spacing: 12) {
            // Player Image
            ZStack(alignment: .bottomTrailing) {
                AsyncImage(url: URL(string: player.image)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .foregroundStyle(.gray.opacity(0.3))
                }
                .frame(width: 90, height: 90)
                .clipShape(Circle())
                .overlay {
                    Circle()
                        .strokeBorder(teamColor, lineWidth: 3)
                }
                
                // Player Number Badge
                Text("\(player.shirtNumber)")
                    .font(.system(size: 14, weight: .black))
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
                    .background(teamColor)
                    .clipShape(Circle())
                    .overlay {
                        Circle()
                            .strokeBorder(.white, lineWidth: 2)
                    }
                    .offset(x: 5, y: 5)
            }
            
            // Player Info
            VStack(spacing: 4) {
                Text(player.name)
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(1)
                    .foregroundStyle(.white)
                
                Text(player.position)
                    .font(.system(size: 13, weight: .medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(teamColor.opacity(0.8))
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
            .font(.system(size: 12))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
    }
}