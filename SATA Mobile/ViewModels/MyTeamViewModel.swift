import Foundation

@MainActor
class MyTeamViewModel: ObservableObject {
    @Published var games: [Game] = []
    private let teamId: Int
    
    init() {
        self.teamId = UserDefaults.standard.integer(forKey: "teamId")
    }
    
    func fetchTeamGames() async {
    }
}
