//
//  ClearBackgroundView.swift
//  SATA Mobile
//
//  Created by João Franco on 07/01/2025.
//

import SwiftUI

// MARK: - TransparentBackgroundView
/// A SwiftUI view that creates a transparent background effect
/// by manipulating the background color of its parent views
struct TransparentBackgroundView: UIViewRepresentable {
    /// The color to set as the background
    var color: UIColor = .clear
    
    /// Creates and returns the underlying UIView for the transparent background
    /// - Parameter context: The context in which the view is created
    /// - Returns: A configured UIView instance
    func makeUIView(context: Context) -> UIView {
        let view = _UIBackgroundBlurView()
        view.color = color
        return view
    }
    
    /// Updates the view with new configuration
    /// - Parameters:
    ///   - uiView: The view to update
    ///   - context: The context in which the update occurs
    func updateUIView(_ uiView: UIView, context: Context) {}
}

// MARK: - _UIBackgroundBlurView
/// A private implementation class that handles the background color manipulation
private class _UIBackgroundBlurView: UIView {
    /// The color to apply to the background
    var color: UIColor = .clear
    
    /// Configures the background color when the view's layout changes
    override func layoutSubviews() {
        super.layoutSubviews()
        superview?.superview?.backgroundColor = color
    }
}
