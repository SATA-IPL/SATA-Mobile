import SwiftUI

struct NameInputView: View {
    @StateObject private var userProfile = UserProfileManager()
    @State private var name = ""
    @State private var showContent = false

    var body: some View {
        Form {
            Section {
                VStack(spacing: 12) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .symbolEffect(.bounce)
                        .font(.system(size: 50))
                        .foregroundStyle(.accent)
                    
                    Text("What's your name?")
                        .font(.title2.weight(.bold))
                    
                    Text("Let us know how to address you")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .listRowInsets(EdgeInsets())
            }
            
            Section {
                TextField("Your name", text: $name)
                    .textContentType(.givenName)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.words)
            } header: {
                Text("Personal Info")
                    .textCase(nil)
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
            
            Section {
                NavigationLink("Continue", destination: TeamSelectionView())
                    .font(.headline)
            }
        }
        .navigationTitle("Create Profile")
        .navigationBarTitleDisplayMode(.large)
        .scrollContentBackground(.hidden)
        .background {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
        }
    }
}
