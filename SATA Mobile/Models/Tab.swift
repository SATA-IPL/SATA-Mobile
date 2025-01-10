//
//  Tab.swift
//  SATA Mobile
//
//  Created by João Franco on 10/01/2025.
//

import Foundation

/// Represents the main navigation tabs in the application
enum Tab: String, Hashable {
    case games
    case myTeam
    case profile
    
    var title: String {
        switch self {
        case .games:
            return "Games"
        case .myTeam:
            return "My Team"
        case .profile:
            return "Profile"
        }
    }
}
