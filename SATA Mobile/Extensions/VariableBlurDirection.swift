//
//  VariableBlurDirection.swift
//  SATA Mobile
//
//  Created by João Franco on 29/12/2024.
//

import SwiftUI
import UIKit
import CoreImage.CIFilterBuiltins
import QuartzCore

// MARK: - Enums

/// Defines the direction of the variable blur effect
public enum VariableBlurDirection {
    /// Blur effect starts from top (blurred) to bottom (clear)
    case blurredTopClearBottom
    /// Blur effect starts from bottom (blurred) to top (clear)
    case blurredBottomClearTop
}

// MARK: - SwiftUI View

/// A SwiftUI view that implements a variable blur effect
public struct VariableBlurView: UIViewRepresentable {
    /// Maximum blur radius for the effect
    public var maxBlurRadius: CGFloat = 20
    
    /// Direction of the blur effect
    public var direction: VariableBlurDirection = .blurredTopClearBottom
    
    /// Offset coefficient for the blur start position
    ///
    /// By default, variable blur starts from 0 blur radius and linearly increases to `maxBlurRadius`.
    /// Setting `startOffset` to a small negative coefficient (e.g. -0.1) will start blur from larger
    /// radius value which might look better in some cases.
    public var startOffset: CGFloat = 0

    public func makeUIView(context: Context) -> VariableBlurUIView {
        VariableBlurUIView(maxBlurRadius: maxBlurRadius, direction: direction, startOffset: startOffset)
    }

    public func updateUIView(_ uiView: VariableBlurUIView, context: Context) {
    }
}

// MARK: - UIKit Implementation

/// A UIKit view that implements the variable blur effect using CAFilter
/// Credit: https://github.com/jtrivedi/VariableBlurView
open class VariableBlurUIView: UIVisualEffectView {
    
    // MARK: - Initialization
    
    /// Creates a new variable blur view with the specified parameters
    /// - Parameters:
    ///   - maxBlurRadius: Maximum blur radius
    ///   - direction: Direction of the blur effect
    ///   - startOffset: Offset coefficient for the blur start position
    public init(maxBlurRadius: CGFloat = 20, direction: VariableBlurDirection = .blurredTopClearBottom, startOffset: CGFloat = 0) {
        super.init(effect: UIBlurEffect(style: .regular))

        // `CAFilter` is a private QuartzCore class that dynamically create using Objective-C runtime.
        guard let CAFilter = NSClassFromString("CAFilter")! as? NSObject.Type else {
            print("[VariableBlur] Error: Can't find CAFilter class")
            return
        }
        guard let variableBlur = CAFilter.self.perform(NSSelectorFromString("filterWithType:"), with: "variableBlur").takeUnretainedValue() as? NSObject else {
            print("[VariableBlur] Error: CAFilter can't create filterWithType: variableBlur")
            return
        }

        // The blur radius at each pixel depends on the alpha value of the corresponding pixel in the gradient mask.
        // An alpha of 1 results in the max blur radius, while an alpha of 0 is completely unblurred.
        let gradientImage = makeGradientImage(startOffset: startOffset, direction: direction)

        variableBlur.setValue(maxBlurRadius, forKey: "inputRadius")
        variableBlur.setValue(gradientImage, forKey: "inputMaskImage")
        variableBlur.setValue(true, forKey: "inputNormalizeEdges")

        // We use a `UIVisualEffectView` here purely to get access to its `CABackdropLayer`,
        // which is able to apply various, real-time CAFilters onto the views underneath.
        let backdropLayer = subviews.first?.layer

        // Replace the standard filters (i.e. `gaussianBlur`, `colorSaturate`, etc.) with only the variableBlur.
        backdropLayer?.filters = [variableBlur]

        // Get rid of the visual effect view's dimming/tint view, so we don't see a hard line.
        for subview in subviews.dropFirst() {
            subview.alpha = 0
        }
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle Methods
    
    open override func didMoveToWindow() {
        // Fixes visible pixelization at unblurred edge
        guard let window, let backdropLayer = subviews.first?.layer else { return }
        backdropLayer.setValue(window.screen.scale, forKey: "scale")
    }
    
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        // Note: super.traitCollectionDidChange(previousTraitCollection) crashes the app
    }
    
    // MARK: - Private Methods
    
    /// Creates a gradient image used as the blur mask
    /// - Parameters:
    ///   - width: Width of the gradient image
    ///   - height: Height of the gradient image
    ///   - startOffset: Offset for the gradient start position
    ///   - direction: Direction of the gradient
    /// - Returns: A CGImage containing the gradient
    private func makeGradientImage(width: CGFloat = 100, height: CGFloat = 100, startOffset: CGFloat, direction: VariableBlurDirection) -> CGImage {
        let ciGradientFilter =  CIFilter.linearGradient()
        ciGradientFilter.color0 = CIColor.black
        ciGradientFilter.color1 = CIColor.clear
        ciGradientFilter.point0 = CGPoint(x: 0, y: height)
        ciGradientFilter.point1 = CGPoint(x: 0, y: startOffset * height) // small negative value looks better with vertical lines
        if case .blurredBottomClearTop = direction {
            ciGradientFilter.point0.y = 0
            ciGradientFilter.point1.y = height - ciGradientFilter.point1.y
        }
        return CIContext().createCGImage(ciGradientFilter.outputImage!, from: CGRect(x: 0, y: 0, width: width, height: height))!
    }
}
