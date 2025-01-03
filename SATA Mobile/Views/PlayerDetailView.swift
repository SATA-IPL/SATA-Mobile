import SwiftUI

struct PlayerDetailView: View {
    let playerId: String
    let team: Team
    @StateObject private var viewModel = PlayerDetailViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                loadingPlayerView
            case .error(let message):
                ContentUnavailableView("Unable to Load Player", 
                    systemImage: "person.fill.questionmark",
                    description: Text(message))
            case .loaded:
                if let player = viewModel.playerDetail {
                    mainContent(player)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.init(hex: team.colors?[0] ?? "#FFFFF"), .clear]),
                startPoint: .top,
                endPoint: .bottom
            ).opacity(0.2)
        )
        .task {
            await viewModel.fetchPlayerDetail(id: playerId)
        }
    }
    
    private func mainContent(_ player: PlayerDetail) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(team.name) | \(player.position)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Text(player.name)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)
                    }
                    Spacer()
                    
                    AsyncImage(url: URL(string: player.imageURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 75, height: 75)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    } placeholder: {
                        Color.gray.opacity(0.3)
                            .frame(width: 75, height: 75)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                }
                
                // Player Info Grid
                Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 8) {
                    GridRow {
                        PlayerInfoItem(label: "HEIGHT", value: player.height)
                        PlayerInfoItem(label: "NATIONALITY", value: player.citizenship)
                    }
                    GridRow {
                        PlayerInfoItem(label: "AGE", value: player.age)
                        PlayerInfoItem(label: "FOOT", value: player.foot.uppercased())
                    }
                }
                
                // Market Value Card
                HStack {
                    StatItem(value: player.stats.appearances ?? 0, label: "Games")
                    Spacer()
                    StatItem(value: player.stats.goals ?? 0, label: "Goals")
                    Spacer()
                    StatItem(value: player.stats.assists ?? 0, label: "Assists")
                    Spacer()
                    StatItem(value: player.stats.yellowCards ?? 0, label: "Yellow's")
                    Spacer()
                    StatItem(value: player.stats.redCards ?? 0, label: "Red's")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .padding(.horizontal, 20)
                .background(Material.ultraThin)
                .cornerRadius(15)
            }
            .padding(.horizontal, 24)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: share) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.secondary)
                }
            }
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle")
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var loadingPlayerView: some View {
        ScrollView {
            VStack(spacing: 16) {
                ShimmerLoadingView()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                
                VStack(spacing: 8) {
                    ShimmerLoadingView()
                        .frame(width: 180, height: 24)
                    ShimmerLoadingView()
                        .frame(width: 100, height: 18)
                }
                
                LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 20) {
                    ForEach(0..<6, id: \.self) { _ in
                        ShimmerLoadingView()
                            .frame(height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding()
            }
            .padding(.top)
        }
    }
    
    private func share() {
        // Share functionality to be implemented here
    }
}

// Supporting Views
struct PlayerInfoItem: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 4) {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
        }
    }
}

struct StatItem: View {
    let value: Int
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value, format: .number.notation(.compactName))
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
    }
}
