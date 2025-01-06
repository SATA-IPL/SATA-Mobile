import SwiftUI

struct AboutView: View {
    var body: some View {
        List {
            Section {
                VStack(spacing: 8) {
                    Image(systemName: "soccerball")
                        .font(.system(size: 60))
                        .foregroundStyle(.accent)
                    
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
                Label("João Franco", systemImage: "person.fill")
                Label("Miguel Susano", systemImage: "person.fill")
                Label("Francisco Marques", systemImage: "person.fill")
            }
            
            Section("Teacher") {
                Label("José Carlos Bregieiro Ribeiro", systemImage: "person.fill.checkmark")
            }
            
            Section("Academic Context") {
                Label("Masters in Computer Engineering", systemImage: "graduationcap.fill")
                Label("Mobile Application Development", systemImage: "apps.iphone")
                Label("Polytechnic University of Leiria", systemImage: "building.columns.fill")
            }
        }
        .navigationTitle("About")
    }
}
