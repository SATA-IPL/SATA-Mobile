//
//  ClearBackgroundView.swift
//  SATA Mobile
//
//  Created by João Franco on 07/01/2025.
//

import SwiftUI

struct TransparentBackgroundView: UIViewRepresentable {
    var color: UIColor = .clear
    func makeUIView(context: Context) -> UIView {
        let view = _UIBackgroundBlurView()
        view.color = color
        return view
    }
    func updateUIView(_ uiView: UIView, context: Context) {}
}

class _UIBackgroundBlurView: UIView {
    var color :UIColor = .clear
    override func layoutSubviews() {
        super.layoutSubviews()
        superview?.superview?.backgroundColor = color
    }
}
