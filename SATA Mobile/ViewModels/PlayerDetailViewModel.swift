import Foundation

@MainActor
class PlayerDetailViewModel: ObservableObject {
    @Published var playerDetail: PlayerDetail?
    @Published var state: ViewState = .loading
    
    func fetchPlayerDetail(id: String) async {
        state = .loading
        guard let url = URL(string: "http://144.24.177.214:5000/players/\(id)") else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            playerDetail = try JSONDecoder().decode(PlayerDetail.self, from: data)
            state = .loaded
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}
