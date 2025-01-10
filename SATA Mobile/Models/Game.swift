import Foundation

struct Game: Identifiable, Decodable {
  let awayScore: Int
  let awayTeam: Team
  let date: String
  let gameId: Int
  let homeScore: Int
  let homeTeam: Team
  let hour: String
  let image: String?
  let state: String
  let venue: String?
  let stadium: Stadium?
  let videoUrl: String?
  let leagueId: Int?
  let timestamp: String?
  
  var id: Int { gameId }
  
  var fullImageUrl: String? {
    guard let image = image else { return nil }
    return "http://144.24.177.214:5000\(image)"
  }
  
  enum CodingKeys: String, CodingKey {
    case awayScore = "away_score"
    case awayTeam = "away_team"
    case date
    case gameId = "game_id"
    case homeScore = "home_score"
    case homeTeam = "home_team"
    case hour
    case image
    case state
    case venue
    case stadium
    case videoUrl = "video_url"
    case leagueId = "league_id"
    case teamGameStats
    case timestamp
  }
  
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    awayScore = try container.decode(Int.self, forKey: .awayScore)
    awayTeam = try container.decode(Team.self, forKey: .awayTeam)
    date = try container.decode(String.self, forKey: .date)
    gameId = try container.decode(Int.self, forKey: .gameId)
    homeScore = try container.decode(Int.self, forKey: .homeScore)
    homeTeam = try container.decode(Team.self, forKey: .homeTeam)
    hour = try container.decode(String.self, forKey: .hour)
    image = try container.decodeIfPresent(String.self, forKey: .image)
    state = try container.decode(String.self, forKey: .state)
    venue = try container.decodeIfPresent(String.self, forKey: .venue)
    stadium = try container.decodeIfPresent(Stadium.self, forKey: .stadium)
    videoUrl = try container.decodeIfPresent(String.self, forKey: .videoUrl)
    leagueId = try container.decodeIfPresent(Int.self, forKey: .leagueId)
    timestamp = try container.decodeIfPresent(String.self, forKey: .timestamp)
  }
  
  static func == (lhs: Game, rhs: Game) -> Bool {
    lhs.id == rhs.id
  }
}
