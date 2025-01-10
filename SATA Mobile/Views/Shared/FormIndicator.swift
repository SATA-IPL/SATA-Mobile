//
//  FormIndicator.swift
//  SATA Mobile
//
//  Created by João Franco on 10/01/2025.
//

import SwiftUI

/// A view that displays form indicators
struct FormIndicator: View {
    let result: String
    
    var backgroundColor: Color {
        switch result {
        case "W": return .green.opacity(0.8)
        case "L": return .red.opacity(0.8)
        case "D": return .orange.opacity(0.8)
        case "empty": return .gray.opacity(0.2) // Placeholder color
        default: return .gray.opacity(0.8)
        }
    }
    
    var body: some View {
        Text(result == "empty" ? "" : result)
            .font(.system(.caption2, weight: .black))
            .foregroundColor(.white)
            .frame(width: 20, height: 20)
            .background(backgroundColor)
            .clipShape(Circle())
    }
}
