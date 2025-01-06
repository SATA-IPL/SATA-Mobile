import SwiftUI

struct TimelineEventView: View {
    let event: EventType
    let description: String
    let teamColor: String
    
    var body: some View {
        HStack(spacing: 15) {
            Circle()
                .fill(event.color.gradient)
                .frame(width: 30, height: 30)
                .overlay {
                    Image(systemName: event.icon)
                        .font(.caption.bold())
                        .foregroundStyle(event == .yellowCard ? .black : .white)
                }
            
            Text(description)
                .font(.callout)
            
            Spacer()
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(hex: teamColor))
                        .frame(width: 4)
                }
        }
        .padding(.horizontal)
    }
}
