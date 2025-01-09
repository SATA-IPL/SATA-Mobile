import Foundation

class FavoriteStadiums {
    static let shared = FavoriteStadiums()
    private let defaults = UserDefaults.standard
    private let favoritesKey = "FavoriteStadiums"
    
    private init() {}
    
    var favoriteStadiumIds: Set<String> {
        get {
            let array = defaults.array(forKey: favoritesKey) as? [String] ?? []
            return Set(array)
        }
        set {
            defaults.set(Array(newValue), forKey: favoritesKey)
        }
    }
    
    func toggleFavorite(stadiumId: String) {
        var favorites = favoriteStadiumIds
        if favorites.contains(stadiumId) {
            favorites.remove(stadiumId)
        } else {
            favorites.insert(stadiumId)
        }
        favoriteStadiumIds = favorites
    }
    
    func isFavorite(stadiumId: String) -> Bool {
        favoriteStadiumIds.contains(stadiumId)
    }
}
