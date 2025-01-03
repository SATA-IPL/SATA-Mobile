struct Stats: Codable {
    let appearances: Int?
    let assists: Int?
    let goals: Int?
    let minutesPlayed: Int?
    let redCards: Int?
    let yellowCards: Int?
}

struct PlayerDetail: Codable {
    let age: String
    let citizenship: String
    let club: String
    let dateOfBirth: String
    let foot: String
    let height: String
    let id: String
    let imageURL: String
    let marketValue: Int
    let name: String
    let position: String
    let shirtNumber: String
    let stats: Stats
}
