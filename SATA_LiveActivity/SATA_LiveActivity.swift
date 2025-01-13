//
//  SATA_LiveActivity.swift
//  SATA_LiveActivity
//
//  Created by João Franco on 05/01/2025.
//

import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Main Live Activity Configuration
/// Defines the main widget and Dynamic Island for displaying live game activities.
struct SATA_LiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: GameActivityAttributes.self) { context in
            ///Live Activity Widget
            ///Functionality: Display live game information
            ///Is used in: Lock Screen, Home Screen and Always On Display
            SATAGameWidgetView(context: context)
        } dynamicIsland: { context in
            /// Configuration for Dynamic Island in Expanded state.
            DynamicIsland {
                /// Leading region (When Tapped) | Home Team
                DynamicIslandExpandedRegion(.leading) {
                    VStack {
                        Text(context.attributes.homeTeam.prefix(3).uppercased())
                            .font(.system(size: 18, weight: .bold))
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(.white.opacity(0.1)))
                            .background(Circle().fill(Color(hex: context.attributes.homeTeamColor)))
                            .foregroundColor(Color(hex: context.attributes.homeTeamColor).textColor())
                        Text("\(context.state.homeScore)")
                            .font(.system(size: 28, weight: .black).width(.compressed))
                    }
                }
                
                /// Trailing region (When Tapped) | Away Team
                DynamicIslandExpandedRegion(.trailing) {
                    VStack {
                        Text(context.attributes.awayTeam.prefix(3).uppercased())
                            .font(.system(size: 18, weight: .bold))
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(.white.opacity(0.1)))
                            .background(Circle().fill(Color(hex: context.attributes.awayTeamColor)))
                            .foregroundColor(Color(hex: context.attributes.awayTeamColor).textColor())
                        Text("\(context.state.awayScore)")
                            .font(.system(size: 28, weight: .black).width(.compressed))
                    }
                }
                
                /// Center region (When Tapped) | Game Time and Status
                DynamicIslandExpandedRegion(.center) {
                    HStack(spacing: 16) {
                        VStack(spacing: 4) {
                            Text("\(context.state.gameTime)'")
                                .font(.system(.title2, weight: .bold).width(.compressed))
                            Text(context.state.gameStatus.capitalized)
                                .font(.system(.headline, weight: .bold).width(.compressed))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                /// Bottom region (When Tapped) | Last Event
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.system(.headline, weight: .bold).width(.compressed))
                            .foregroundStyle(.primary)
                        Text(context.state.lastEvent)
                            .font(.system(.headline, weight: .bold).width(.compressed))
                            .foregroundStyle(.primary)
                    }
                }
            }
            /// Configuration for Dynamic Island in Collapsed state.
            /// Leading region | Home Team
            compactLeading: {
                HStack(spacing: 10) {
                    Text(context.attributes.homeTeam.prefix(3).uppercased())
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(hex: context.attributes.homeTeamColor))
                    Text("\(context.state.homeScore)")
                        .font(.system(size: 25))
                        .fontWeight(.black)
                        .fontWidth(.compressed)
                }
            }
            /// Trailing region | Away Team
            compactTrailing: {
                HStack(spacing: 4) {
                    Text("\(context.state.awayScore)")
                        .font(.system(size: 25))
                        .fontWeight(.black)
                        .fontWidth(.compressed)
                    Text(context.attributes.awayTeam.prefix(3).uppercased())
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(hex: context.attributes.awayTeamColor))
                }
            }
            ///Configuration for Dynamic Island in Minimal state (When Used with other activities)
            ///Minimal region | Score
            minimal: {
                Text("\(context.state.homeScore)")
                    .foregroundColor(Color(hex: context.attributes.homeTeamColor))
                + Text("-")
                + Text("\(context.state.awayScore)")
                    .foregroundColor(Color(hex: context.attributes.awayTeamColor))
            }
        }
        .supplementalActivityFamilies([.small])
    }
}

// MARK: - Live Activity Widget View
/// Main view for displaying game information in different widget sizes.
struct SATAGameWidgetView: View {
    @Environment(\.activityFamily) var activityFamily
    @Environment(\.isActivityFullscreen) var isStandByMode
    let context: ActivityViewContext<GameActivityAttributes>
    
    var body: some View {
        switch activityFamily {
            
        /// For Lock Screen, Home Screen and Always On Display
        case .medium:
            HStack(spacing: 0) {
                VStack{
                    ZStack {
                        if (isStandByMode == false)
                        {
                            Rectangle()
                                .fill(.black)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            Rectangle()
                                .fill(.thinMaterial)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            LinearGradient(
                                colors: [Color(hex: context.attributes.homeTeamColor), Color(hex: context.attributes.awayTeamColor)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .opacity(0.5)
                            .blur(radius: 50)
                        }
                        HStack(spacing: 20) {
                            VStack {
                                Text(context.attributes.homeTeam.prefix(3).uppercased())
                                    .font(.system(size: 24, weight: .bold))
                                    .frame(width: 50, height: 50)
                                    .background(Circle().fill(Color(hex: context.attributes.homeTeamColor)))
                                    .foregroundColor(Color(hex: context.attributes.homeTeamColor).textColor())
                                Text(context.attributes.homeTeam)
                                    .font(.system(.footnote, weight: .semibold).width(.condensed))
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .clipped()
                            
                            Text("\(context.state.homeScore)")
                                .foregroundStyle(.primary)
                                .font(.system(size: 50, weight: .black, design: .default).width(.compressed))
                            
                            VStack {
                                Text("\(context.state.gameTime)'")
                                    .font(.system(.title2, weight: .bold).width(.compressed))
                                Text(context.state.gameStatus.capitalized)
                                    .font(.system(.headline, weight: .bold).width(.compressed))
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .clipped()
                            
                            Text("\(context.state.awayScore)")
                                .foregroundStyle(.primary)
                                .font(.system(size: 50, weight: .black, design: .default).width(.compressed))
                            
                            VStack {
                                Text(context.attributes.awayTeam.prefix(3).uppercased())
                                    .font(.system(size: 24, weight: .bold))
                                    .frame(width: 50, height: 50)
                                    .background(Circle().fill(Color(hex: context.attributes.awayTeamColor)))
                                    .foregroundColor(Color(hex: context.attributes.awayTeamColor).textColor())
                                Text(context.attributes.awayTeam)
                                    .font(.system(.footnote, weight: .semibold).width(.condensed))
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .clipped()
                        }
                        .padding()
                    }
                    
                    HStack {
                        Image(systemName: "clock.fill")
                            .font(.system(.footnote, weight: .bold))
                        Text(context.state.lastEvent)
                            .font(.system(.footnote, weight: .bold))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .padding(.bottom, 12)
                }
            }
            .preferredColorScheme(.dark)
            .frame(maxWidth: .infinity)
            .frame(height: 140)
            .clipped()
            
        /// For Apple Watch Live Activity (watchOS 11)
        /// Documentation: https://developer.apple.com/videos/play/wwdc2024/10068
        case .small:
            ZStack {
                // Base layer
                Rectangle()
                    .fill(.black)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Blur material layer
                Rectangle()
                    .fill(.thinMaterial)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Gradient overlay
                LinearGradient(
                    colors: [Color(hex: context.attributes.homeTeamColor), Color(hex: context.attributes.awayTeamColor)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .opacity(0.5)
                .blur(radius: 50)
                
                // Content
                VStack(spacing: 0){
                    HStack(spacing: 8) {
                        // Home team
                        VStack {
                            Text(context.attributes.homeTeam.prefix(3).uppercased())
                                .font(.system(size: 14, weight: .bold))
                                .frame(width: 30, height: 30)
                                .background(Circle().fill(Color(hex: context.attributes.homeTeamColor).textColor()))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        
                        // Home score
                        Text("\(context.state.homeScore)")
                            .foregroundStyle(.primary)
                            .font(.system(size: 32, weight: .black).width(.compressed))
                        
                        // Game info
                        VStack(spacing: 2) {
                            Text("\(context.state.gameTime)'")
                                .font(.system(.footnote, weight: .bold).width(.compressed))
                        }
                        .frame(maxWidth: .infinity)
                        
                        // Away score
                        Text("\(context.state.awayScore)")
                            .foregroundStyle(.primary)
                            .font(.system(size: 32, weight: .black).width(.compressed))
                        
                        // Away team
                        VStack {
                            Text(context.attributes.awayTeam.prefix(3).uppercased())
                                .font(.system(size: 14, weight: .bold))
                                .frame(width: 30, height: 30)
                                .background(Circle().fill(Color.init(hex: context.attributes.awayTeamColor).textColor()))
                                .foregroundColor(.black)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    
                    // Separator
                    Rectangle()
                        .fill(.secondary.opacity(0.5))
                        .frame(height: 1)
                        .padding(.vertical,4)
                    
                    // Last event
                    VStack{
                        Text(context.state.lastEvent)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.top, 4)
                    }
                    .padding(.horizontal, 8)
                }
            }
            .preferredColorScheme(.dark)
            .frame(maxHeight: .infinity)
            .clipped()
        @unknown default:
            // For Future Activity Families
            EmptyView()
        }
    }
}
