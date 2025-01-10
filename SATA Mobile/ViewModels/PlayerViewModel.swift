import Foundation
import SwiftUI

enum LoadingState {
    case loading
    case loaded
    case error(String)
}

@MainActor
class PlayerViewModel: ObservableObject {
    @Published private(set) var players: [Player] = []
    @Published private(set) var state: LoadingState = .loading
    @Published var showFavoritesOnly = false {
        didSet {
            objectWillChange.send()
        }
    }
    
    @Published var selectedPlayer: Player?
    @Published var gameStats: PlayerGameStats?
    
    private let favoritesKey = "FavoritePlayers"
    
    var filteredPlayers: [Player] {
        showFavoritesOnly ? players.filter { $0.isFavorite } : players
    }
    
    func fetchPlayers() async {
        state = .loading
        
        guard let url = URL(string: "http://144.24.177.214:5000/players") else {
            state = .error("Invalid URL")
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            var fetchedPlayers = try JSONDecoder().decode([Player].self, from: data)
            
            // Restore favorites
            let favorites = getFavorites()
            for index in fetchedPlayers.indices {
                fetchedPlayers[index].isFavorite = favorites.contains(fetchedPlayers[index].id)
            }
            
            players = fetchedPlayers
            state = .loaded
        } catch {
            state = .error("Failed to fetch players: \(error.localizedDescription)")
        }
    }
    
    private func getFavorites() -> Set<String> {
        let defaults = UserDefaults.standard
        let favoriteIds = defaults.object(forKey: favoritesKey) as? [String] ?? []
        return Set(favoriteIds)
    }
    
    private func saveFavorites(_ favorites: Set<String>) {
        let defaults = UserDefaults.standard
        defaults.set(Array(favorites), forKey: favoritesKey)
    }
    
    func toggleFavorite(for player: Player) {
        var favorites = getFavorites()
        
        if favorites.contains(player.id) {
            favorites.remove(player.id)
        } else {
            favorites.insert(player.id)
        }
        
        saveFavorites(favorites)
        
        // Update players array
        if let index = players.firstIndex(where: { $0.id == player.id }) {
            players[index].isFavorite.toggle()
        }
        
        // Update selected player if needed
        if selectedPlayer?.id == player.id {
            selectedPlayer?.isFavorite.toggle()
        }
        
        // Force view update
        objectWillChange.send()
    }
    
    func fetchPlayerDetail(id: String) async {
        state = .loading
        guard let url = URL(string: "http://144.24.177.214:5000/players/\(id)") else {
            state = .error("Invalid URL for player detail endpoint")
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            selectedPlayer = try JSONDecoder().decode(Player.self, from: data)
            state = .loaded
        } catch {
            state = .error("Failed to fetch player detail: \(error.localizedDescription)")
        }
    }
    
    func fetchPlayerGameStats(gameId: Int, playerId: String) async {
        guard let url = URL(string: "http://144.24.177.214:5000/game/\(gameId)/statistics/\(playerId)") else {
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            gameStats = try JSONDecoder().decode(PlayerGameStats.self, from: data)
        } catch {
            print("Error fetching game stats: \(error.localizedDescription)")
        }
    }
}
