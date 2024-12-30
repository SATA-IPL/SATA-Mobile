import Foundation

struct Team: Codable, Identifiable {
    let id: String
    let name: String
    let image: String?
    let players: [Player]?
    let colors: [String]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case image
        case players
        case colors
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Handle both String and Int cases for id
        if let intID = try? container.decode(Int.self, forKey: .id) {
            self.id = String(intID)
        } else {
            self.id = try container.decode(String.self, forKey: .id)
        }
        name = try container.decode(String.self, forKey: .name)
        image = try container.decodeIfPresent(String.self, forKey: .image)
        players = try container.decodeIfPresent([Player].self, forKey: .players)
        colors = try container.decodeIfPresent([String].self, forKey: .colors)
    }
}

