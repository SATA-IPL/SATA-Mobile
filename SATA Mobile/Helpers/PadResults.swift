//
//  PadResults.swift
//  SATA Mobile
//
//  Created by João Franco on 10/01/2025.
//

import Foundation
import SwiftUI

/// Pads an array of results to a specified count (Used in Form Guide)
/// - Parameters:
///   - results: The array of results to pad
///   - count: The desired length of the array
/// - Returns: The padded array of results
public func padResults(_ results: [String], count: Int = 5) -> [String] {
    let padding = Array(repeating: "empty", count: max(0, count - results.count))
    return Array(results.prefix(count)) + padding
}
