//
//  TeamSelectionView.swift
//  SATA Mobile
//
//  Created by João Franco on 05/01/2025.
//

import SwiftUI

struct TeamSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var teamsViewModel: TeamsViewModel
    @State private var showContent = false
    @State private var selectedTeam: Team?
    @State private var currentTeamId: String?
    @State private var searchText = ""
    @State private var showingConfirmation = false
    
    private var filteredTeams: [Team] {
        guard !searchText.isEmpty else { return teamsViewModel.teams }
        return teamsViewModel.teams.filter { 
            $0.name.lowercased().contains(searchText.lowercased())
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.blue.opacity(0.01)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                List(filteredTeams) { team in
                    teamRow(for: team)
                        .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowBackground(Color.primary.opacity(0.1))
                }
                .scrollContentBackground(.hidden)
                .navigationTitle("Select Team")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Confirm") {
                            showingConfirmation = true
                        }
                        .disabled(selectedTeam == nil)
                        .bold()
                    }
                }
                .alert("Confirm Team Selection", isPresented: $showingConfirmation) {
                    Button("Cancel", role: .cancel) { }
                    Button("Confirm") {
                        if let team = selectedTeam {
                            teamsViewModel.setTeam(team: team)
                            dismiss()
                        }
                    }
                } message: {
                    if let team = selectedTeam {
                        Text("Are you sure you want to select \(team.name)?")
                    }
                }
                .listStyle(.insetGrouped)
                .searchable(text: $searchText, placement: .navigationBarDrawer, prompt: "Search teams")
                .animation(.easeOut(duration: 0.3), value: filteredTeams)
                .overlay {
                    if teamsViewModel.teams.isEmpty {
                        ContentUnavailableView {
                            Label("No Teams", systemImage: "person.3")
                        } description: {
                            Text("Teams will appear here once loaded")
                        }
                    }
                }
                .onAppear {
                    withAnimation(.easeOut(duration: 0.6)) {
                        showContent = true
                    }
                    currentTeamId = teamsViewModel.currentTeam
                    if let currentId = teamsViewModel.currentTeam,
                       let team = teamsViewModel.teams.first(where: { $0.id == currentId }) {
                        selectedTeam = team
                    }
                }
            }
        }
    }
    
    private func teamRow(for team: Team) -> some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: team.image ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                Image(systemName: "person.3")
                    .foregroundStyle(.secondary)
                    .font(.title2)
            }
            .frame(width: 44, height: 44)
            
            Text(team.name)
                .font(.body)
                .foregroundStyle(.primary)
            
            Spacer()
            
            if selectedTeam?.id == team.id {
                Image(systemName: "checkmark.circle.fill")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.accent)
                    .font(.title3)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.3)) {
                selectedTeam = team
            }
        }
    }
}
