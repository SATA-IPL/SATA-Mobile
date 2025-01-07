//
//  ShowcaseDynamicIsland.swift
//  SATA Mobile
//
//  Created by João Franco on 05/01/2025.
//

import SwiftUI
import OnBoardingKit

struct ShowcaseDynamicIslandView: View {
    @Binding var path: NavigationPath
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.blue.opacity(0.01)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Image("DynamicIsland")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 275)
                    .mask(
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: .black, location: 0),
                                .init(color: .black, location: 0.8),
                                .init(color: .clear, location: 1)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .background(Color.clear)
                
                VStack(spacing: 16) {
                    Text("Dynamic Island")
                        .font(.system(size: 32, weight: .bold))
                    
                    Text("Stay updated with live activities right from your Dynamic Island. Track game scores, match times, and more without opening the app.")
                        .font(.system(size: 16))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                
                Spacer()
                
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
}
