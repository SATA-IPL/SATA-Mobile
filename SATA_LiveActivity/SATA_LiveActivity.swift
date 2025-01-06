//
//  SATA_LiveActivity.swift
//  SATA_LiveActivity
//
//  Created by João Franco on 05/01/2025.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct SATA_LiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: GameActivityAttributes.self) { context in
            SATAGameWidgetView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack {
                        Text(context.attributes.homeTeam.prefix(3).uppercased())
                            .font(.system(size: 18, weight: .bold))
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(Color(hex: context.attributes.homeTeamColor)))
                            .foregroundColor(Color(hex: context.attributes.homeTeamColor).textColor())
                        Text("\(context.state.homeScore)")
                            .font(.system(size: 28, weight: .black).width(.compressed))
                    }
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    VStack {
                        Text(context.attributes.awayTeam.prefix(3).uppercased())
                            .font(.system(size: 18, weight: .bold))
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(Color(hex: context.attributes.awayTeamColor)))
                            .foregroundColor(Color(hex: context.attributes.awayTeamColor).textColor())
                        Text("\(context.state.awayScore)")
                            .font(.system(size: 28, weight: .black).width(.compressed))
                    }
                }
                
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
            } compactLeading: {
                HStack(spacing: 10) {
                    Text(context.attributes.homeTeam.prefix(3).uppercased())
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(hex: context.attributes.homeTeamColor))
                    Text("\(context.state.homeScore)")
                        .font(.system(size: 25))
                        .fontWeight(.black)
                        .fontWidth(.compressed)
                }
            } compactTrailing: {
                HStack(spacing: 4) {
                    Text("\(context.state.awayScore)")
                        .font(.system(size: 25))
                        .fontWeight(.black)
                        .fontWidth(.compressed)
                    Text(context.attributes.awayTeam.prefix(3).uppercased())
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(hex: context.attributes.awayTeamColor))
                }
            } minimal: {
                Text("\(context.state.homeScore)-\(context.state.awayScore)")
            }
        }
        .supplementalActivityFamilies([.small])
    }
}

struct SATAGameWidgetView: View {
    @Environment(\.activityFamily) var activityFamily
    @Environment(\.isActivityFullscreen) var isStandByMode
    let context: ActivityViewContext<GameActivityAttributes>
    
    var body: some View {
        switch activityFamily {
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
            .frame(maxWidth: .infinity)
            .frame(height: 140)
            .clipped()
        case .small:
            HStack(spacing: 0) {
                ZStack {
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
                    
                    HStack(spacing: 8) {
                        VStack {
                            Text(context.attributes.homeTeam.prefix(3).uppercased())
                                .font(.system(size: 14, weight: .bold))
                                .frame(width: 30, height: 30)
                                .background(Circle().fill(Color(hex: context.attributes.homeTeamColor)))
                                .foregroundColor(Color(hex: context.attributes.homeTeamColor).textColor())
                        }
                        .frame(maxWidth: .infinity)
                        
                        Text("\(context.state.homeScore)")
                            .foregroundStyle(.primary)
                            .font(.system(size: 32, weight: .black).width(.compressed))
                        
                        VStack {
                            Text("\(context.state.gameTime)'")
                                .font(.system(.footnote, weight: .bold).width(.compressed))
                        }
                        .frame(maxWidth: .infinity)
                        
                        Text("\(context.state.awayScore)")
                            .foregroundStyle(.primary)
                            .font(.system(size: 32, weight: .black).width(.compressed))
                        
                        VStack {
                            Text(context.attributes.awayTeam.prefix(3).uppercased())
                                .font(.system(size: 14, weight: .bold))
                                .frame(width: 30, height: 30)
                                .background(Circle().fill(Color(hex: context.attributes.awayTeamColor)))
                                .foregroundColor(Color(hex: context.attributes.awayTeamColor).textColor())
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 8)
                }
            }
            .frame(maxWidth: .infinity)
            .clipped()
            .mask { RoundedRectangle(cornerRadius: 16, style: .continuous) }
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(.thinMaterial, lineWidth: 1)
            )
        }
    }
}

struct SharedImageLoader {
    static let appGroupId = "group.com.joaofranco.SATA-Mobile"
    
    static func getImageFilePath(for imageName: String) -> String? {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) else {
            return nil
        }
        return containerURL.appendingPathComponent(imageName).path
    }
    
    static func loadImage(named imageName: String) -> UIImage? {
        guard let path = getImageFilePath(for: imageName) else { return nil }
        return UIImage(contentsOfFile: path)
    }
}

struct TeamColumn: View {
    let imageName: String
    let team: String
    let score: Int
    
    var body: some View {
        VStack {
            Text(team.prefix(3).uppercased())
                .font(.system(size: 24, weight: .bold))
                .frame(width: 40, height: 40)
                .background(Circle().fill(Color.gray)) // You might want to pass team color as parameter
                .foregroundColor(.white)
            Text(team)
                .font(.caption)
            Text("\(score)")
                .font(.title)
                .bold()
        }
    }
}

struct TeamScoreView: View {
    let teamName: String
    let score: Int
    
    var body: some View {
        HStack {
            Text(teamName.prefix(3).uppercased())
                .font(.system(size: 14, weight: .bold))
                .frame(width: 30, height: 30)
                .background(Circle().fill(Color.gray)) // You might want to pass team color as parameter
                .foregroundColor(.white)
            VStack(alignment: .leading) {
                Text(teamName)
                    .font(.caption2)
                Text("\(score)")
                    .font(.headline)
                    .bold()
            }
        }
    }
}

extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
