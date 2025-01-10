struct Stats: Codable {
    let appearances: Int?
    let assists: Int?
    let goals: Int?
    let minutesPlayed: Int?
    let redCards: Int?
    let yellowCards: Int?
}

struct Player: Codable, Identifiable {
    let id: String
    let image: String
    let name: String
    let position: String
    let shirtNumber: String
    var isFavorite: Bool = false  // Now properly mutable
    
    // Added fields from PlayerDetail
    let age: String?
    let citizenship: String?
    let club: String?
    let dateOfBirth: String?
    let foot: String?
    let height: String?
    let marketValue: Int?
    let stats: Stats?
    
    private enum CodingKeys: String, CodingKey {
        case id 
        case image, imageURL
        case name
        case position 
        case shirtNumber
        case age
        case citizenship
        case club
        case dateOfBirth
        case foot
        case height
        case marketValue
        case stats
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        position = try container.decode(String.self, forKey: .position)
        shirtNumber = try container.decode(String.self, forKey: .shirtNumber)
        
        // Try decoding image, fallback to imageURL
        if let imageValue = try? container.decode(String.self, forKey: .image) {
            image = imageValue
        } else {
            image = try container.decode(String.self, forKey: .imageURL)
        }
        
        // Optional fields from PlayerDetail
        age = try? container.decode(String.self, forKey: .age)
        citizenship = try? container.decode(String.self, forKey: .citizenship)
        club = try? container.decode(String.self, forKey: .club)
        dateOfBirth = try? container.decode(String.self, forKey: .dateOfBirth)
        foot = try? container.decode(String.self, forKey: .foot)
        height = try? container.decode(String.self, forKey: .height)
        marketValue = try? container.decode(Int.self, forKey: .marketValue)
        stats = try? container.decode(Stats.self, forKey: .stats)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(position, forKey: .position)
        try container.encode(shirtNumber, forKey: .shirtNumber)
        try container.encode(image, forKey: .imageURL)
    }
}