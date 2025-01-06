//
//  SataLiveActivityLiveActivity.swift
//  SataLiveActivity
//
//  Created by João Franco on 05/01/2025.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct SataLiveActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct SataLiveActivityLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SataLiveActivityAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension SataLiveActivityAttributes {
    fileprivate static var preview: SataLiveActivityAttributes {
        SataLiveActivityAttributes(name: "World")
    }
}

extension SataLiveActivityAttributes.ContentState {
    fileprivate static var smiley: SataLiveActivityAttributes.ContentState {
        SataLiveActivityAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: SataLiveActivityAttributes.ContentState {
         SataLiveActivityAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: SataLiveActivityAttributes.preview) {
   SataLiveActivityLiveActivity()
} contentStates: {
    SataLiveActivityAttributes.ContentState.smiley
    SataLiveActivityAttributes.ContentState.starEyes
}
