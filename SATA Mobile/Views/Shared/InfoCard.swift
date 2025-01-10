//
//  CardStyle.swift
//  SATA Mobile
//
//  Created by João Franco on 10/01/2025.
//

import SwiftUI

/// Constants for card styling
enum CardStyle {
    static let padding: CGFloat = 16
    static let cornerRadius: CGFloat = 16
    static let spacing: CGFloat = 12
    static let headerSpacing: CGFloat = 8
}

/// A standard info card view
struct InfoCard<Content: View>: View {
    let title: String
    let icon: String
    let content: () -> Content
    
    init(
        title: String,
        icon: String,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: CardStyle.spacing) {
            HStack(spacing: CardStyle.headerSpacing) {
                Image(systemName: icon)
                    .font(.system(.subheadline, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text(title)
                    .font(.system(.subheadline, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            
            content()
        }
        .padding(CardStyle.padding)
        .background {
            RoundedRectangle(cornerRadius: CardStyle.cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.03), radius: 3, x: 0, y: 1)
        }
        .padding(.horizontal)
    }
}
