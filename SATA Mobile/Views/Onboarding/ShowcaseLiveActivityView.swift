//
//  WatchLiveActivityWelcomeView.swift
//  SATA Mobile
//
//  Created by João Franco on 05/01/2025.
//

import SwiftUI
import OnBoardingKit

struct ShowcaseLiveActivityView: View {
    let onComplete: () -> Void
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.blue.opacity(0.01)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Image("WatchLiveActivity")
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
                    Text("Apple Watch Updates")
                        .font(.system(size: 32, weight: .bold))
                    
                    Text("Get live game updates right on your wrist. Follow scores, match progress, and important events with a quick glance at your Apple Watch.")
                        .font(.system(size: 16))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                
                Spacer()
                
                VStack(spacing: 20) {
                    Text("Requires Apple Watch with watchOS 11 or later. Make sure your Watch is paired and notifications are enabled.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                    
                    Button(action: {
                        onComplete()
                    }) {
                        Text("Get Started")
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
