//
//  TeamSelectionView.swift
//  SATA Mobile
//
//  Created by João Franco on 05/01/2025.
//

import SwiftUI

struct TeamSelectionView: View {
    @ObservedObject var teamsViewModel: TeamsViewModel = TeamsViewModel()
    @State private var showContent = false
    @State private var selectedTeam: Team?
    @State private var currentTeamId: String?
    @State private var searchText = ""
    
    private var filteredTeams: [Team] {
        guard !searchText.isEmpty else { return teamsViewModel.teams }
        return teamsViewModel.teams.filter { 
            $0.name.lowercased().contains(searchText.lowercased())
        }
    }
    
    var body: some View {
        List {
            Section {
                VStack(spacing: 8) {
                    Image(systemName: "person.3.sequence.fill")  // Better SF Symbol
                        .symbolEffect(.bounce)
                        .font(.system(size: 50))
                        .foregroundStyle(.accent)
                    
                    Text("Choose Your Team")
                        .font(.title2.weight(.bold))
                    
                    Text("Select the team you want to follow")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .listRowInsets(EdgeInsets())
            }
            
            Section {
                ForEach(filteredTeams) { team in
                    teamRow(for: team)
                        .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }  // Proper separator alignment
                }
            } header: {
                Text("Available Teams")
                    .textCase(nil)
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
        }
        .navigationTitle("Select Team")
        .navigationBarTitleDisplayMode(.large)
        .listStyle(.insetGrouped)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, placement: .navigationBarDrawer)
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
        .task {
            await teamsViewModel.fetchTeams()
        }
    }
    
    private func teamRow(for team: Team) -> some View {
        HStack(spacing: 16) {
            AsyncImage(url: URL(string: team.image ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                Image(systemName: "photo")
                    .foregroundStyle(.secondary)
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(team.name)
                    .font(.body.weight(.medium))
            }
            
            Spacer()
            
            if selectedTeam?.id == team.id {
                Image(systemName: "checkmark.circle.fill")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.accent)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation {
                selectedTeam = team
                teamsViewModel.setTeam(team: team)
            }
        }
        .padding(.vertical, 4)
    }
}
