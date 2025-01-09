struct HeadToHeadStats: Codable {
    let draws: Int
    let team1_id: Int
    let team1_wins: Int
    let team2_id: Int
    let team2_wins: Int
    let games: [LastGameScore]
}

 struct LastGameScore: Codable {
    let home_score: Int
    let away_score: Int
    let home_team: Int
    let away_team: Int
    let result: String
}

