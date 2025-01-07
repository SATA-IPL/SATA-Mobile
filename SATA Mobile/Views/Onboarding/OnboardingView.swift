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
    
    func handleCompletion() {
        dismiss()
    }
    
    var body: some View {
        NavigationStack(path: $path) {
            WelcomeView(path: $path, onDismiss: handleCompletion)
                .navigationBarBackButtonHidden()
                .navigationDestination(for: OnboardingPage.self) { page in
                    Group {
                        switch page {
                        case .welcome:
                            WelcomeView(path: $path, onDismiss: handleCompletion)
                        case .siri:
                            ShowcaseSiriView(path: $path)
                        case .dynamicIsland:
                            ShowcaseDynamicIslandView(path: $path)
                        case .standBy:
                            ShowcaseStandByView(path: $path)
                        case .watchLiveActivity:
                            ShowcaseLiveActivityView(onComplete: handleCompletion)
                        }
                    }
                }
        }
        .interactiveDismissDisabled()
    }
}
