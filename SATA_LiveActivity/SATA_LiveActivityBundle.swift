//
//  SATA_LiveActivityBundle.swift
//  SATA_LiveActivity
//
//  Created by João Franco on 05/01/2025.
//

import WidgetKit
import SwiftUI

@main
struct SATA_LiveActivityBundle: WidgetBundle {
    var body: some Widget {
        // Live activity / Dynamic Island Widget
        SATA_LiveActivity()
        // Widget control for opening the main app ((Lock Screen or Control Center))
        OpenAppControl()
        // Widget control for navigating to the team screen (Lock Screen or Control Center)
        OpenTeamScreenControl()
    }
}
