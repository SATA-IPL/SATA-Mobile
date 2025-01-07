//
//  ShowcaseSiriView.swift
//  SATA Mobile
//
//  Created by João Franco on 05/01/2025.
//

import SwiftUI
import OnBoardingKit

struct ShowcaseSiriView: View {
    @Binding var path: NavigationPath
    
    var body: some View {
        VStack(spacing: 24) {
            
            // iPad illustration
            Image("Siri")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .background(Color.gray.opacity(0.2))
                .frame(height: 275)
            
            // Main content
            VStack(spacing: 16) {
                Text("Siri")
                    .font(.system(size: 32, weight: .bold))
                
                Text("Use Siri to ask questions about your next team games, open the app, or integrate with Shortcuts for automated workflows. Just say \"Hey Siri, what can I do here?\" to get started.")
                    .font(.system(size: 16))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            
            Spacer()
            
            // Footer content
            VStack(spacing: 20) {
                Text("This feature uses App Intents and Shortcuts to enable quick access and automation through Siri or Shortcuts app.")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                
                Button(action: {
                    path.append(OnboardingPage.dynamicIsland)
                }) {
                    Text("Continue")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.accent.opacity(0.6))
                        .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
        }
        .ignoresSafeArea(edges: .top)
    }
}