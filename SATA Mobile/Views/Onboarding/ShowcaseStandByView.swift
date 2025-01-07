//
//  StandByWelcomeView.swift
//  SATA Mobile
//
//  Created by João Franco on 05/01/2025.
//

import SwiftUI
import OnBoardingKit

struct ShowcaseStandByView: View {
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
                Image("StandBy")
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
                    Text("StandBy Mode")
                        .font(.system(size: 32, weight: .bold))
                    
                    Text("Keep track of your games while charging. View scores, upcoming matches, and team statistics in a glanceable format when your iPhone is on its side.")
                        .font(.system(size: 16))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                
                Spacer()
                
                VStack(spacing: 20) {
                    Text("StandBy requires iOS 17 or later and works when your iPhone is charging and positioned sideways.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                    
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
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                }
            }
            .ignoresSafeArea(edges: .top)
        }
    }
}
