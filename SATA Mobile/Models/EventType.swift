
import SwiftUICore

enum EventType: String, CaseIterable, Identifiable {
    case goal = "Goal"
    case assist = "Assist"
    case finish = "Finish"
    case corner = "Corner"
    case foul = "Foul"
    case freeKick = "Free kick"
    case defense = "Defense"
    case interception = "Interception"
    case offside = "Offside"
    case tackle = "Tackle"
    case penalty = "Penalty"
    case substitution = "Substitution"
    case yellowCard = "Yellow Card"
    case redCard = "Red Card"
    
    var icon: String {
        switch self {
        case .goal: return "soccerball"
        case .assist: return "arrow.right"
        case .finish: return "target"
        case .corner: return "flag.fill"
        case .foul: return "exclamationmark.triangle"
        case .freeKick: return "dot.circle.and.hand.point.up.left.fill"
        case .defense: return "shield.fill"
        case .interception: return "arrow.up.right.and.arrow.down.left"
        case .offside: return "flag.2.crossed"
        case .tackle: return "figure.soccer"
        case .penalty: return "exclamationmark.circle"
        case .substitution: return "arrow.left.arrow.right"
        case .yellowCard: return "square.fill"
        case .redCard: return "square.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .goal: return .green
        case .assist: return .blue
        case .finish: return .orange
        case .corner: return .mint
        case .foul: return .red
        case .freeKick: return .purple
        case .defense: return .indigo
        case .interception: return .teal
        case .offside: return .gray
        case .tackle: return .brown
        case .penalty: return .pink
        case .substitution: return .blue
        case .yellowCard: return .yellow
        case .redCard: return .red
        }
    }
    
    var id: String { self.rawValue }
}
