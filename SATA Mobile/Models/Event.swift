import Foundation

struct Event: Codable, Identifiable, Equatable {
    let event_id: Int
    let event_type: String
    let game_id: Int
    let player_id: String?
    let player_in: String?
    let player_out: String?
    let timestamp: String
    let team_colors: [String]
    let team_id: Int
    
    var id: Int { event_id }
    
    var minute: Int {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        guard let date = formatter.date(from: timestamp) else { return 0 }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.minute], from: date)
        return components.minute ?? 0
    }
     var eventTypeEnum: EventType? {
        EventType(rawValue: event_type)
    }
}
