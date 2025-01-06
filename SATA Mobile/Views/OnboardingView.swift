//
//  OnboardingSheet.swift
//  SATA Mobile
//
//  Created by João Franco on 27/12/2024.
//

import SwiftUI
import Shimmer
import OnBoardingKit

struct FeatureRow: View {
    let systemImage: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {  // Adjusted spacing
            Image(systemName: systemImage)
                .font(.title2)  // Use system font sizing
                .foregroundColor(.accentColor)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {  // Tighter spacing
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

enum OnboardingPage {
    case welcome
    case siri
    case dynamicIsland
    case standBy
    case watchLiveActivity
}

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var path = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $path) {
            SiriView(path: $path)
                .navigationDestination(for: OnboardingPage.self) { page in
                    switch page {
                    case .siri:
                        SiriView(path: $path)
                    case .dynamicIsland:
                        DynamicIslandWelcomeView(path: $path)
                    case .standBy:
                        StandByWelcomeView(path: $path)
                    case .watchLiveActivity:
                        WatchLiveActivityWelcomeView(path: $path)
                    default:
                        EmptyView()
                    }
                }
        }
    }
}
