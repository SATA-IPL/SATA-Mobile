import SwiftUI

/// View for displaying statistical information
struct StatItem: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .fontWeight(.bold)
            Text(label)
                .foregroundStyle(.secondary)
        }
    }
}