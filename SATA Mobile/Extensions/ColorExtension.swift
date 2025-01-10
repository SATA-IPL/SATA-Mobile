//
//  ColorExtension.swift
//  SATA
//
//  Created by João Franco on 04/10/2024.
//

import SwiftUI

// MARK: - Color Hex Initialization
extension Color {
    /// Initializes a Color instance from a hexadecimal string
    /// - Parameter hex: A string representing a hex color code (e.g., "#FF0000" or "FF0000")
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var hexNumber: UInt64 = 0
        let r, g, b: Double
        
        // Remove the leading # if it exists
        if hex.hasPrefix("#") {
            scanner.currentIndex = hex.index(after: hex.startIndex)
        }
        
        if scanner.scanHexInt64(&hexNumber) {
            // Extract RGB components from hex number
            r = Double((hexNumber & 0xff0000) >> 16) / 255
            g = Double((hexNumber & 0x00ff00) >> 8) / 255
            b = Double(hexNumber & 0x0000ff) / 255
            
            self.init(red: r, green: g, blue: b)
        } else {
            // Default to black if parsing fails
            self.init(red: 0, green: 0, blue: 0)
        }
    }
}

// MARK: - Color Utilities
extension Color {
    /// Determines the appropriate text color (black or white) based on the background color's luminance
    /// - Returns: White for dark background colors, black for light background colors
    func textColor() -> Color {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        // Extract RGB components
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        // Calculate relative luminance using standard coefficients
        let luminance = 0.299 * red + 0.587 * green + 0.114 * blue
        
        // Return contrasting text color
        return luminance > 0.5 ? .black : .white
    }
}