import SwiftUI

struct ProfileView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.blue.opacity(0.01)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            ScrollView {
                Text("Profile View")
                //Show selected team id from teamId in UserDefaults
                Text("Selected Team: \(UserDefaults.standard.integer(forKey: "teamId"))")
            }
        }
    }
}
