//
//  PillButton.swift
//  SATA
//
//  Created by João Franco on 01/12/2024.
//

import SwiftUI

struct PillButton: View {
    var action: () -> Void
    var title: String
    var icon: String
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
                    .bold()
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 15)
            .background(Material.ultraThin)
            .background(Color.primary.opacity(0.2)) // Use a specific background color
            .foregroundColor(.primary)
            .cornerRadius(100) // Makes it a pill shape
                        .overlay(
                RoundedRectangle(cornerRadius: 100)
                    .stroke(Material.thin.opacity(0.5), lineWidth: 1)
            )
            .frame(maxWidth: .infinity) // Fills the available width
        }
        .buttonStyle(.plain) // Remove button styling for a cleaner look
    }
}
