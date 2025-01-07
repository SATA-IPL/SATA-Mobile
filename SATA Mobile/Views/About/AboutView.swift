import SwiftUI

struct AboutView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.blue.opacity(0.01)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            List {
                Section {
                    VStack(spacing: 8) {
                        Image(systemName: "soccerball")
                            .font(.system(size: 60))
                            .foregroundStyle(.primary)
                        
                        Text("SATA")
                            .font(.title.bold())
                        
                        Text("Version 1.0.0")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .listRowBackground(Color.clear)
                }
                
                Section("Creators") {
                    Label("João Franco", systemImage: "person.fill").foregroundColor(.primary)
                    Label("Miguel Susano", systemImage: "person.fill").foregroundColor(.primary)
                    Label("Francisco Marques", systemImage: "person.fill").foregroundColor(.primary)
                }.listRowBackground(Color.primary.opacity(0.1))
                
                Section("Teacher") {
                    Label("José Carlos Bregieiro Ribeiro", systemImage: "person.fill.checkmark").foregroundColor(.primary)
                }.listRowBackground(Color.primary.opacity(0.1))
                
                Section("Academic Context") {
                    Label("Masters in Computer Engineering", systemImage: "graduationcap.fill").foregroundColor(.primary)
                    Label("Mobile Application Development", systemImage: "apps.iphone").foregroundColor(.primary)
                    Label("Polytechnic University of Leiria", systemImage: "building.columns.fill").foregroundColor(.primary)
                }.listRowBackground(Color.primary.opacity(0.1))

            }
            .scrollContentBackground(.hidden)
            .listStyle(.insetGrouped)
        }
        .navigationTitle("About")
    }
}
