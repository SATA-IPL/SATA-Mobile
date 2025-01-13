//
//  APIKey.swift
//  SATA Mobile
//
//  Created by João Franco on 01/01/2025.
//

import Foundation
import SwiftUI

/// Manages API key access and validation for the application
/// This enum provides a centralized way to access the API key stored in GenerativeAI-Info.plist
enum APIKey {
    // MARK: - Properties
    
    /// The default API key retrieved from the configuration file
    /// - Returns: A valid API key string
    /// - Throws: Fatal error if the API key is not properly configured
    static var `default`: String {
        // MARK: - Configuration Validation
        
        guard let filePath = Bundle.main.path(forResource: "GenerativeAI-Info", ofType: "plist")
        else {
            fatalError("Couldn't find file 'GenerativeAI-Info.plist'.")
        }
        
        // MARK: - Plist Processing
        
        let plist = NSDictionary(contentsOfFile: filePath)
        guard let value = plist?.object(forKey: "API_KEY") as? String else {
            fatalError("Couldn't find key 'API_KEY' in 'GenerativeAI-Info.plist'.")
        }
        
        // MARK: - Key Validation
        
        if value.starts(with: "_") {
            fatalError(
                "Follow the instructions at https://ai.google.dev/tutorials/setup to get an API key."
            )
        }
        return value
    }
}
