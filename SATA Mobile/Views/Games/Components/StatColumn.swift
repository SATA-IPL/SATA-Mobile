//
//  StatColumn.swift
//  SATA Mobile
//
//  Created by João Franco on 10/01/2025.
//

import SwiftUI

/// A view for displaying statistical columns
/// - Parameters:
///  - title: The title of the column
///  - values: The values to display
///  - isCenter: Whether the text should be centered
///  - teamColor: The color of the team
///  - showBar: Whether to display a progress bar
///  - isLeftTeam: Whether the team is on the left side
///  - Returns: A view displaying the column
struct StatColumn: View {
    let title: String
    let values: [String]
    let isCenter: Bool
    let teamColor: Color?
    let showBar: Bool
    let isLeftTeam: Bool
    
    init(
        title: String,
        values: [String],
        isCenter: Bool = false,
        teamColor: Color? = nil,
        showBar: Bool = false,
        isLeftTeam: Bool = true
    ) {
        self.title = title
        self.values = values
        self.isCenter = isCenter
        self.teamColor = teamColor
        self.showBar = showBar
        self.isLeftTeam = isLeftTeam

        print("StatColumn initialized with values: \(values)")
    }
    
    var body: some View {
        VStack(spacing: 8) {
            if (!title.isEmpty) {
                Text(title)
                    .font(.system(.caption, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            
            ForEach(Array(values.enumerated()), id: \.offset) { index, value in
                VStack(spacing: 4) {
                    Text(value)
                        .font(.system(.callout, weight: isCenter ? .regular : .semibold))
                        .monospacedDigit()
                    
                    if showBar && teamColor != nil {
                        GeometryReader { geometry in
                            let percentage = percentageFromString(value)
                            let width = geometry.size.width * percentage
                            
                            ZStack(alignment: isLeftTeam ? .leading : .trailing) {
                                Capsule()
                                    .fill(.secondary.opacity(0.2))
                                    .frame(height: 3)
                                
                                Capsule()
                                    .fill(teamColor ?? .clear)
                                    .frame(width: width, height: 3)
                            }
                        }
                        .frame(height: 3)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(isCenter ? .center : .leading)
    }
}
