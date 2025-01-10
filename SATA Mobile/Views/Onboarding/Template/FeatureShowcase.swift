import SwiftUI

struct FeatureShowcase<Action: View>: View {
    let imageName: String
    let title: String
    let description: String
    let footnote: String
    let action: Action
    
    init(
        imageName: String,
        title: String,
        description: String,
        footnote: String,
        @ViewBuilder action: () -> Action
    ) {
        self.imageName = imageName
        self.title = title
        self.description = description
        self.footnote = footnote
        self.action = action()
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.blue.opacity(0.01)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 275)
                    .mask(
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: .black, location: 0),
                                .init(color: .black, location: 0.8),
                                .init(color: .clear, location: 1)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .background(Color.clear)
                
                VStack(spacing: 16) {
                    Text(title)
                        .font(.system(size: 32, weight: .bold))
                    
                    Text(description)
                        .font(.system(size: 16))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                
                Spacer()
                
                VStack(spacing: 20) {
                    Text(footnote)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                    
                    action
                        .padding(.horizontal, 24)
                        .padding(.bottom, 16)
                }
            }
            .ignoresSafeArea(edges: .top)
        }
    }
}
