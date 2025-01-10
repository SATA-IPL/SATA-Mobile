//
//  Redacted.swift
//  SATA Mobile
//
//  Created by João Franco on 06/01/2025.
//

import Foundation
import SwiftUI

// MARK: - RedactingView
/// A view that conditionally applies redaction modifiers based on the environment's redaction reasons
struct RedactingView<Input: View, Output: View>: View {
    /// The original content view
    var content: Input
    /// The modifier to apply when content is redacted
    var modifier: (Input) -> Output

    @Environment(\.redactionReasons) private var reasons

    var body: some View {
        if reasons.isEmpty {
            content
        } else {
            modifier(content)
        }
    }
}

// MARK: - View Extension
extension View {
    /// Applies a custom modifier when the view is redacted
    /// - Parameter modifier: A closure that transforms the view when redaction is applied
    /// - Returns: A view that conditionally applies the modifier when redacted
    func whenRedacted<T: View>(
        apply modifier: @escaping (Self) -> T
    ) -> some View {
        RedactingView(content: self, modifier: modifier)
    }
}
