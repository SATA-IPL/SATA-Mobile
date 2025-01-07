import Foundation

struct Statistics: Codable {
    let assist: Int
    let corner: Int
    let defense: Int
    let finish: Int
    let foul: Int
    let freeKick: Int
    let goal: Int
    let interception: Int
    let offside: Int
    let passes: Int
    let penalty: Int
    let redCard: Int
    let substitution: Int
    let tackle: Int
    let yellowCard: Int
    
    enum CodingKeys: String, CodingKey {
        case assist = "Assist"
        case corner = "Corner"
        case defense = "Defense"
        case finish = "Finish"
        case foul = "Foul"
        case freeKick = "Free Kick"
        case goal = "Goal"
        case interception = "Interception"
        case offside = "Offside"
        case passes = "Passes"
        case penalty = "Penalty"
        case redCard = "Red Card"
        case substitution = "Substitution"
        case tackle = "Tackle"
        case yellowCard = "Yellow Card"
    }
}
