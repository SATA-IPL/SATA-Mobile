
import Foundation

@MainActor
class GameCardViewModel: ObservableObject {
    @Published var game: Game?
    @Published var state: ViewState = .loading
    
    func fetchGameDetail(id: Int) async {
        state = .loading
        
        guard let url = URL(string: "http://144.24.177.214:5000/games/\(id)") else {
            print("❌ Invalid URL for game detail endpoint")
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            game = try JSONDecoder().decode(Game.self, from: data)
            state = .loaded
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}