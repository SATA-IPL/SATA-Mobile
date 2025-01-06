import Foundation

struct TeamGameStats: Codable {
    let gameId: Int
    let homeTeamEvents: TeamEvents
    let awayTeamEvents: TeamEvents
}

struct TeamEvents: Codable {
    let goals: Int
    let shots: Int
    let shotsOnTarget: Int
    let possession: Int
    let passes: Int
    let fouls: Int
    let yellowCards: Int
    let redCards: Int
    let offsides: Int
    let corners: Int
    
    enum CodingKeys: String, CodingKey {
        case goals, shots, possession, passes, fouls, offsides, corners
        case shotsOnTarget = "shots_on_target"
        case yellowCards = "yellow_cards"
        case redCards = "red_cards"
    }
}

