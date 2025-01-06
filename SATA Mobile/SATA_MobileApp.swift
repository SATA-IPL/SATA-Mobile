//
//  SATA_MobileApp.swift
//  SATA Mobile
//
//  Created by João Franco on 26/12/2024.
//

import SwiftUI
import Metal

@main
struct SATAMobileApp: App {
   
    var body: some Scene {
        WindowGroup {
            ContentView()
            .preferredColorScheme(.dark)
            .onOpenURL { url in
                if url.scheme == "sata" {
                    print("Widget tapped! URL: \(url)")
                    // Handle navigation or actions here
                }
            }
        }
    }
}
