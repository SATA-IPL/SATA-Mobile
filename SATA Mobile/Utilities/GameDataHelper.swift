//
//  GameDataHelper.swift
//  SATA Mobile
//
//  Created by João Franco on 06/01/2025.
//

import Foundation
import Combine
import SwiftUI

struct GameDataHelper {
    static func fetchUpcomingGame(teamId: Int) async throws -> String {
        guard let url = URL(string: "http://144.24.177.214:5000/upcoming/\(teamId)") else {
            throw NSError(domain: "Invalid URL", code: 1, userInfo: nil)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        struct UpcomingGame: Codable {
            let away_team: Team
            let home_team: Team
            let date: String
            let hour: String
            
            struct Team: Codable {
                let name: String
            }
        }
        
        let game = try JSONDecoder().decode(UpcomingGame.self, from: data)
        
        // Format date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let date = dateFormatter.date(from: game.date) ?? Date()
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let gameDay = calendar.startOfDay(for: date)
        
        let dayDifference = calendar.dateComponents([.day], from: today, to: gameDay).day ?? 0
        
        let dayText: String
        switch dayDifference {
        case 0: dayText = "Today"
        case 1: dayText = "Tomorrow"
        default:
            dateFormatter.dateFormat = "EEEE, MMMM d"
            dayText = "on \(dateFormatter.string(from: date))"
        }
        
        let opponent = game.away_team.name == "Sporting CP" ? game.home_team.name : game.away_team.name
        return "Your next match is \(dayText) at \(game.hour) against \(opponent)"
    }
}
