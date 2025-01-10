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
                            FeatureShowcase(
                                imageName: "Siri",
                                title: "Siri",
                                description: "Use Siri to ask questions about your next team games, open the app, or integrate with Shortcuts for automated workflows. Just say \"Hey Siri, what can I do here?\" to get started.",
                                footnote: "This feature uses App Intents and Shortcuts to enable quick access and automation through Siri or Shortcuts app."
                            ) {
                                PrimaryButton(title: "Continue") {
                                    path.append(OnboardingPage.dynamicIsland)
                                }
                            }
                        case .dynamicIsland:
                            FeatureShowcase(
                                imageName: "DynamicIsland",
                                title: "Dynamic Island",
                                description: "Stay updated with live activities right from your Dynamic Island. Track game scores, match times, and more without opening the app.",
                                footnote: "This feature requires iPhone 14 Pro or later. Live Activities need to be enabled in Settings."
                            ) {
                                PrimaryButton(title: "Continue") {
                                    path.append(OnboardingPage.standBy)
                                }
                            }
                        case .standBy:
                            FeatureShowcase(
                                imageName: "StandBy",
                                title: "StandBy Mode",
                                description: "Keep track of your games while charging. View scores, upcoming matches, and team statistics in a glanceable format when your iPhone is on its side.",
                                footnote: "StandBy requires iOS 17 or later and works when your iPhone is charging and positioned sideways."
                            ) {
                                Button(action: {
                                    path.append(OnboardingPage.watchLiveActivity)
                                }) {
                                    Text("Continue")
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(.accent.opacity(0.6))
                                        .cornerRadius(12)
                                }
                            }
                        case .watchLiveActivity:
                            FeatureShowcase(
                                imageName: "WatchLiveActivity",
                                title: "Apple Watch Updates",
                                description: "Get live game updates right on your wrist. Follow scores, match progress, and important events with a quick glance at your Apple Watch.",
                                footnote: "Requires Apple Watch with watchOS 11 or later. Make sure your Watch is paired and notifications are enabled."
                            ) {
                                PrimaryButton(title: "Get Started", action: handleCompletion)
                            }
                        }
                    }
                }
        }
        .interactiveDismissDisabled()
    }
}
