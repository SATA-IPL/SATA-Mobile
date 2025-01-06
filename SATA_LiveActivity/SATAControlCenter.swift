import WidgetKit
import SwiftUI
import AppIntents

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
