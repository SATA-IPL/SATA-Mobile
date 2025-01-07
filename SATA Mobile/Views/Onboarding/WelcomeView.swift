import SwiftUI
import OnBoardingKit

struct WelcomeView: View {
    @Binding var path: NavigationPath
    @Environment(\.dismiss) private var dismiss
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // App Icon
            Image("Icon")
                .resizable()
                .frame(width: 120, height: 120)
                .cornerRadius(24)
                .padding(.bottom, 16)
            
            // Main content
            VStack(spacing: 16) {
                Text("Welcome to SATA Mobile")
                    .font(.system(size: 32, weight: .bold))
                
                Text("Your ultimate companion for tracking games, scores, and team updates. Get ready for an enhanced sports experience.")
                    .font(.system(size: 16))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            
            Spacer()
            
            // Footer content
            VStack(spacing: 20) {
                Text("Discover all the features we've prepared to keep you connected with your favorite teams.")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                
                Button(action: {
                    path.append(OnboardingPage.siri)
                }) {
                    Text("See Features")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.accent.opacity(0.6))
                        .cornerRadius(12)
                }
                .padding(.horizontal, 24)

                Button("Go to App") {
                    onDismiss()
                }
                .font(.system(size: 17))
                .foregroundColor(.accent)
                .padding(.bottom, 16)
            }
        }
    }
}
