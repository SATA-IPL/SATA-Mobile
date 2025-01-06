//
//  DynamicIslandWelcomeView.swift
//  SATA Mobile
//
//  Created by João Franco on 05/01/2025.
//

import SwiftUI
import OnBoardingKit

struct DynamicIslandWelcomeView: View {
    @Binding var path: NavigationPath
    
    var body: some View {
        VStack(spacing: 24) {
            // Dynamic Island illustration
            Image("DynamicIsland")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .background(Color.gray.opacity(0.2))
                .frame(height: 275)
            
            // Main content
            VStack(spacing: 16) {
                Text("Dynamic Island")
                    .font(.system(size: 32, weight: .bold))
                
                Text("Stay updated with live activities right from your Dynamic Island. Track game scores, match times, and more without opening the app.")
                    .font(.system(size: 16))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            
            Spacer()
            
            // Footer content
            VStack(spacing: 20) {
                Text("This feature requires iPhone 14 Pro or later. Live Activities need to be enabled in Settings.")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                
                Button(action: {
                    path.append(OnboardingPage.standBy)
                }) {
                    Text("Continue")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
        }
        .ignoresSafeArea(edges: .top)
    }
}
