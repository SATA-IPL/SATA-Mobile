//
//  Per.swift
//  SATA Mobile
//
//  Created by João Franco on 10/01/2025.
//

import Foundation

func percentageFromString(_ string: String) -> Double {
    if let value = Double(string.replacingOccurrences(of: "%", with: "")) {
        return value / 100.0
    }
    return 0
}
