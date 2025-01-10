//
//  StatBar.swift
//  SATA Mobile
//
//  Created by João Franco on 10/01/2025.
//

import SwiftUI

/// A view for displaying statistical bars
/// - Parameters:
///  - leftValue: The value for the left bar
///  - rightValue: The value for the right bar
///  - leftColor: The color for the left bar
///  - rightColor: The color for the right bar
///  - Returns: A view displaying the statistical bars

struct StatBar: View {
    let leftValue: Int
    let rightValue: Int
    let leftColor: Color
    let rightColor: Color
    
    private var leftPercentage: CGFloat {
        let total = CGFloat(leftValue + rightValue)
        return total > 0 ? CGFloat(leftValue) / total : 0.5
    }
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                Rectangle()
                    .fill(leftColor)
                    .frame(width: geometry.size.width * leftPercentage)
                
                Rectangle()
                    .fill(rightColor)
                    .frame(width: geometry.size.width * (1 - leftPercentage))
            }
            .frame(height: 4)
            .clipShape(Capsule())
        }
        .frame(height: 4)
    }
}
