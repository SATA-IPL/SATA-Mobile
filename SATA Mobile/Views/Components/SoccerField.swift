import SwiftUI

class FieldBackgroundModel: ObservableObject {
    let fieldPattern: some View = GeometryReader { geo in
        Path { path in
            let stripeWidth: CGFloat = 30
            for x in stride(from: 0, through: geo.size.width, by: stripeWidth) {
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: geo.size.height))
            }
        }
        .stroke(Color.white.opacity(0.05), lineWidth: 15)
    }
}

struct SoccerFieldView: View {
    let homeTeam: Team
    let awayTeam: Team
    let gameId: Int
    @StateObject private var backgroundModel = FieldBackgroundModel()
    @State private var playerPositions: [String: CGPoint] = [:]
    
    // Calculate positions once and cache them
    private func calculatePositions(in size: CGSize) {
        guard playerPositions.isEmpty else { return } // Only calculate once
        
        let basePositions: [(CGFloat, CGFloat)] = [
            (0.95, 0.5), (0.85, 0.20), (0.85, 0.4), (0.85, 0.6), (0.85, 0.80),
            (0.70, 0.30), (0.70, 0.5), (0.70, 0.70), (0.60, 0.15), (0.58, 0.5), (0.60, 0.85)
        ]
        
        let width = size.width
        let height = size.height
        let dotTotalHeight: CGFloat = -10
        let yOffset = dotTotalHeight / 2
        
        // Pre-calculate all positions
        for (index, position) in basePositions.enumerated() {
            // Home team positions
            let homeX = (1.0 - position.0) * width
            let homeY = position.1 * height - yOffset
            playerPositions["home_\(index)"] = CGPoint(x: homeX, y: homeY)
            
            // Away team positions
            let awayX = position.0 * width
            let awayY = position.1 * height - yOffset
            playerPositions["away_\(index)"] = CGPoint(x: awayX, y: awayY)
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Simplified background without shader
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "#1A472A"), Color(hex: "#2E8B57")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .opacity(0.8)
                    }
                    .overlay {
                        backgroundModel.fieldPattern
                    }
                
                // Enhanced field lines with glow effect
                SoccerFieldLines()
                    .opacity(0.7)
                    .drawingGroup()
                    .shadow(color: .white.opacity(0.3), radius: 2, x: 0, y: 0)
                
                // Player layer with enhanced shadows
                PlayersLayer(
                    homePlayers: homeTeam.players?.prefix(11).enumerated().map { ($0, $1) } ?? [],
                    awayPlayers: awayTeam.players?.prefix(11).enumerated().map { ($0, $1) } ?? [],
                    positions: playerPositions,
                    homeColor: Color(hex: homeTeam.colors?[0] ?? "#FFFFFF"),
                    awayColor: Color(hex: awayTeam.colors?[0] ?? "#00C0FF"),
                    homeTeam: homeTeam,
                    awayTeam: awayTeam,
                    gameId: gameId
                )
                .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            .drawingGroup()
            .onAppear {
                calculatePositions(in: geometry.size)
            }
            .onChange(of: geometry.size) { newSize in
                calculatePositions(in: newSize)
            }
        }
    }
}

struct PlayersLayer: View {
    let homePlayers: [(Int, Player)]
    let awayPlayers: [(Int, Player)]
    let positions: [String: CGPoint]
    let homeColor: Color
    let awayColor: Color
    let homeTeam: Team
    let awayTeam: Team
    let gameId: Int
    
    var body: some View {
        ZStack {
            // Home team players
            ForEach(homePlayers, id: \.1.id) { index, player in
                if let position = positions["home_\(index)"] {
                    PlayerDot(player: player, teamColor: homeColor, team: homeTeam, gameId: gameId)
                        .position(position)
                }
            }
            
            // Away team players
            ForEach(awayPlayers, id: \.1.id) { index, player in
                if let position = positions["away_\(index)"] {
                    PlayerDot(player: player, teamColor: awayColor, team: awayTeam, gameId: gameId)
                        .position(position)
                }
            }
        }
    }
}

struct SoccerFieldLines: View {
    var body: some View {
        Canvas { context, size in
            let lineColor = Color.white
            
            // Outline
            context.stroke(
                Path { path in
                    path.addRect(CGRect(origin: .zero, size: size))
                },
                with: .color(lineColor),
                lineWidth: 2
            )
            
            // Center line
            context.stroke(
                Path { path in
                    path.move(to: CGPoint(x: size.width/2, y: 0))
                    path.addLine(to: CGPoint(x: size.width/2, y: size.height))
                },
                with: .color(lineColor),
                lineWidth: 2
            )
            
            // Center circle
            context.stroke(
                Circle().path(in: CGRect(x: size.width/2 - size.height/6,
                                         y: size.height/2 - size.height/6,
                                         width: size.height/3,
                                         height: size.height/3)),
                with: .color(lineColor),
                lineWidth: 2
            )
            
            // Center dot
            context.fill(
                Circle().path(in: CGRect(x: size.width/2 - 4,
                                         y: size.height/2 - 4,
                                         width: 8,
                                         height: 8)),
                with: .color(lineColor)
            )
            
            let penaltyAreaWidth = size.width * 0.16
            let penaltyAreaHeight = size.height * 0.4
            
            // Corner arcs
            let cornerRadius: CGFloat = size.height * 0.04
            for (x, y) in [(0, 0), (size.width, 0), (0, size.height), (size.width, size.height)] {
                context.stroke(
                    Path { path in
                        path.addArc(
                            center: CGPoint(x: x, y: y),
                            radius: cornerRadius,
                            startAngle: Angle(degrees: x == 0 ? (y == 0 ? 0 : -90) : (y == 0 ? 90 : 180)),
                            endAngle: Angle(degrees: x == 0 ? (y == 0 ? 90 : 0) : (y == 0 ? 180 : 270)),
                            clockwise: false
                        )
                    },
                    with: .color(lineColor),
                    lineWidth: 2
                )
            }
            
            // Penalty areas
            for isLeft in [true, false] {
                let x = isLeft ? 0 : size.width - penaltyAreaWidth
                let penaltyAreaY = (size.height - penaltyAreaHeight) / 2
                
                // Main penalty box
                context.stroke(
                    Path { path in
                        path.addRect(CGRect(x: x,
                                            y: penaltyAreaY,
                                            width: penaltyAreaWidth,
                                            height: penaltyAreaHeight))
                    },
                    with: .color(lineColor),
                    lineWidth: 2
                )
                
                // Goal box - smaller proportions
                let goalBoxWidth = penaltyAreaWidth * 0.35
                let goalBoxHeight = penaltyAreaHeight * 0.4
                let goalBoxX = isLeft ? 0 : size.width - goalBoxWidth
                let goalBoxY = (size.height - goalBoxHeight) / 2
                context.stroke(
                    Path { path in
                        path.addRect(CGRect(x: goalBoxX,
                                            y: goalBoxY,
                                            width: goalBoxWidth,
                                            height: goalBoxHeight))
                    },
                    with: .color(lineColor),
                    lineWidth: 2
                )
                
                // Penalty spot at correct FIFA distance
                let penaltySpotX = isLeft ? (penaltyAreaWidth * 0.75) : (size.width - penaltyAreaWidth * 0.75)
                let penaltySpotY = size.height * 0.5
                
                // Arc that matches FIFA specifications
                let arcRadius = penaltyAreaWidth * 0.5  // Radius based on box width instead of height
                
                if isLeft {
                    // Left penalty arc - exactly touching penalty box
                    context.stroke(
                        Path { path in
                            path.addArc(
                                center: CGPoint(x: penaltySpotX, y: penaltySpotY),
                                radius: arcRadius,
                                startAngle: Angle(degrees: -50),
                                endAngle: Angle(degrees: 50),
                                clockwise: false
                            )
                        },
                        with: .color(lineColor),
                        lineWidth: 2
                    )
                } else {
                    // Right penalty arc - exactly touching penalty box
                    context.stroke(
                        Path { path in
                            path.addArc(
                                center: CGPoint(x: penaltySpotX, y: penaltySpotY),
                                radius: arcRadius,
                                startAngle: Angle(degrees: 130),
                                endAngle: Angle(degrees: 230),
                                clockwise: false
                            )
                        },
                        with: .color(lineColor),
                        lineWidth: 2
                    )
                }
                
                // Penalty spot
                context.fill(
                    Circle().path(in: CGRect(
                        x: penaltySpotX - 3,
                        y: penaltySpotY - 3,
                        width: 6,
                        height: 6
                    )),
                    with: .color(lineColor)
                )
            }
        }
    }
}

struct PlayerDot: View {
    let player: Player
    let teamColor: Color
    let team: Team
    let gameId: Int  // Add gameId parameter
    @State private var isSheetPresented = false
    
    var body: some View {
        VStack(spacing: 2) {
            Circle()
                .fill(.ultraThinMaterial)
                .overlay {
                    Circle()
                        .fill(teamColor)
                        .padding(1)
                        .shadow(color: teamColor.opacity(0.5), radius: 2, x: 0, y: 0)
                }
                .overlay {
                    Text(player.shirtNumber)
                        .font(.system(size: 12, weight: .black))
                        .foregroundColor(teamColor.textColor())
                }
                .frame(width: 26, height: 26)
                .onTapGesture {
                    isSheetPresented.toggle()
                }
            
            Text(player.name.split(separator: " ").last ?? "")
                .font(.system(size: 8, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background {
                    Capsule()
                        .fill(.black.opacity(0.6))
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                }
        }
        .sheet(isPresented: $isSheetPresented) {
            NavigationStack {
                PlayerDetailView(playerId: player.id, team: team, gameId: gameId)
            }
        }
    }
}