//
//  AnimatedColorsMeshGradientView.swift
//  SATA Mobile
//
//  Created by João Franco on 28/12/2024.
//

import SwiftUI

struct AnimatedColorsMeshGradientView: View {
    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSince1970 / 2
            let noise1 = sin(time * 1.3) * 0.1
            let noise2 = cos(time * 1.7) * 0.1
            let x = (sin(time) + 1) / 2 + noise1
            let y = (cos(time) + 1) / 2 + noise2
            
            MeshGradient(width: 3, height: 3, points: [
                [0, 0], [0.5, 0], [1, 0],
                [0, 0.5], [Float(x), Float(y)], [1, 0.5],
                [0, 1], [0.5, 1], [1, 1]
            ], colors: [
                .black, .black, .black,
                .black, .accent.opacity(0.2), .black,
                .black, .black, .black
            ],
            smoothsColors: true)
            .blur(radius: 50)
            .ignoresSafeArea()
        }
    }
}

#Preview {
  AnimatedColorsMeshGradientView()
}
