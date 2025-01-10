import WidgetKit
import SwiftUI
import AppIntents

/// Widget to Open the Main App SATA from the Lock Screen or Control Center
struct OpenAppControl: ControlWidget {
    static let kind: String = "com.example.MyApp.OpenAppControl"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind) {
            ControlWidgetButton(action: LaunchAppIntent()) {
                Label("Open SATA", systemImage: "soccerball")
            }
        }
        .displayName("Open MyApp")
        .description("Launches MyApp from Control Center.")
    }
}

/// Widget to Open the Favourite Team Screen on SATA from the Lock Screen or Control Center
struct OpenTeamScreenControl: ControlWidget {
    static let kind: String = "com.example.MyApp.OpenTeamScreenControl"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind) {
            ControlWidgetButton(action: ShowTeamGames()) {
                Label("Show Team on SATA", systemImage: "star.fill")
            }
        }
        .displayName("See Team on SATA")
        .description("Shows the team on SATA from Control Center.")
    }
}
