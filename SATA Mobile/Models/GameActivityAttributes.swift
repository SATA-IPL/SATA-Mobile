import ActivityKit
import Foundation
import UIKit

struct GameActivityAttributes: ActivityAttributes {
    public typealias ContentState = GameState
    
    let homeTeam: String
    let awayTeam: String
    let homeTeamColor: String
    let awayTeamColor: String
    
    struct GameState: Codable, Hashable {
        var homeScore: Int
        var awayScore: Int
        var gameStatus: String
        var gameTime: String
        var lastEvent: String
    }
    
    init(homeTeam: String, awayTeam: String, homeTeamColor: String, awayTeamColor: String) {
        self.homeTeam = homeTeam
        self.awayTeam = awayTeam
        self.homeTeamColor = homeTeamColor
        self.awayTeamColor = awayTeamColor
    }
    
    // Custom coding keys to exclude images from direct encoding
    enum CodingKeys: CodingKey {
        case homeTeam
        case awayTeam
        case homeTeamColor
        case awayTeamColor
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(homeTeam, forKey: .homeTeam)
        try container.encode(awayTeam, forKey: .awayTeam)
        try container.encode(homeTeamColor, forKey: .homeTeamColor)
        try container.encode(awayTeamColor, forKey: .awayTeamColor)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        homeTeam = try container.decode(String.self, forKey: .homeTeam)
        awayTeam = try container.decode(String.self, forKey: .awayTeam)
        homeTeamColor = try container.decode(String.self, forKey: .homeTeamColor)
        awayTeamColor = try container.decode(String.self, forKey: .awayTeamColor)
    }
}
