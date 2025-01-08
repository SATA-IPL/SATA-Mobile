struct Player: Codable, Identifiable {
    let id: String
    let image: String
    let name: String
    let position: String
    let shirtNumber: String
    
    private enum CodingKeys: String, CodingKey {
        case id 
        case image, imageURL
        case name
        case position 
        case shirtNumber 
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