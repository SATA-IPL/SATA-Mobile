//
//  OnboardingSheet.swift
//  SATA Mobile
//
//  Created by João Franco on 27/12/2024.
//

import SwiftUI

struct FeatureRow: View {
    let systemImage: String
    let title: String
    let description: String
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 16) {
                Image(systemName: systemImage)
                    .font(.system(size: 32))
                    .foregroundColor(.accentColor)
                    .frame(width: geometry.size.width * 0.2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(width: geometry.size.width * 0.7)
            }
            .frame(maxWidth: .infinity)
        }
        .frame(height: 60)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showLogo = false
    @State private var showTitle = false
    @State private var showFeatures = false
    @State private var showButton = false
    @State private var isAnimating = true
    
    var body: some View {
        VStack {
            Spacer()
            Image(systemName: "soccerball")
                .renderingMode(.original)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 75)
                .padding(.top, 20)
                .padding(.bottom, 20)
                .offset(y: showLogo ? 0 : -50)
                .opacity(showLogo ? 1 : 0)
            
            Text("Welcome to SATA")
                .font(.system(.largeTitle, weight: .bold))
                .frame(maxWidth: .infinity)
                .clipped()
                .multilineTextAlignment(.center)
                .padding(.bottom, 52)
                .offset(y: showTitle ? 0 : 30)
                .opacity(showTitle ? 1 : 0)
            
            VStack(spacing: 16) {
                FeatureRow(
                    systemImage: "gamecontroller.fill",
                    title: "Play Games",
                    description: "Enjoy our selection of interactive games"
                )
                
                FeatureRow(
                    systemImage: "person.2.fill",
                    title: "Connect with Friends",
                    description: "Challenge others and compete for high scores"
                )
                
                FeatureRow(
                    systemImage: "trophy.fill",
                    title: "Earn Rewards",
                    description: "Collect points and unlock achievements"
                )
            }
            .padding(.bottom, 32)
            .offset(y: showFeatures ? 0 : 50)
            .opacity(showFeatures ? 1 : 0)
            
            Spacer()
            Button(action: {
                dismiss()
            }) {
                Text("Continue")
                    .font(.system(.callout, weight: .semibold))
                    .padding()
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .foregroundColor(.accentColor)
                    .background(.accent.opacity(0.1))
                    .mask { RoundedRectangle(cornerRadius: 16, style: .continuous) }
                    .padding(.bottom)
            }
            .offset(y: showButton ? 0 : 30)
            .opacity(showButton ? 1 : 0)
        }
        .padding(.horizontal, 29)
        .padding(.vertical)
        .background {
            AnimatedColorsMeshGradientView()
            .blur(radius: 60)
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                showLogo = true
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                showTitle = true
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.4)) {
                showFeatures = true
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.6)) {
                showButton = true
            }
        }
    }
}
