import Foundation
import Testing
@testable import VuvuzelaCore

// Helpers — build standings rows and live matches without touching the network.
private func team(_ abbr: String, rank: Int,
                  w: Int = 0, d: Int = 0, l: Int = 0,
                  gf: Int = 0, ga: Int = 0) -> TeamRow {
    TeamRow(
        id: abbr, abbreviation: abbr, displayName: abbr, logoURL: nil,
        rank: rank, gamesPlayed: w + d + l, wins: w, draws: d, losses: l,
        goalsFor: gf, goalsAgainst: ga, goalDiff: gf - ga, points: w * 3 + d,
        qualificationStatus: .unknown
    )
}

private func group(_ abbr: String, _ teams: [TeamRow]) -> GroupStanding {
    GroupStanding(id: abbr, name: "Group \(abbr)", abbreviation: abbr, teams: teams)
}

private func liveMatch(_ home: String, _ hs: Int, _ away: String, _ as_: Int,
                       group: String = "A") -> Match {
    Match(
        id: "\(home)-\(away)",
        homeTeam: MatchTeam(abbreviation: home, displayName: home, score: hs),
        awayTeam: MatchTeam(abbreviation: away, displayName: away, score: as_),
        kickoff: Date(), status: .live, minute: 30,
        groupName: "Group \(group)", roundName: nil
    )
}

@MainActor
@Suite("Live score projection")
struct LiveScoresTests {

    // A trailing team that wins live should gain points/goal-diff and climb the table.
    @Test func winningSideClimbsTable() {
        let store = WorldCupStore()
        var groups = [group("A", [
            team("ARG", rank: 1, w: 1, gf: 2, ga: 0),
            team("MEX", rank: 2, w: 1, gf: 1, ga: 0),
            team("FRA", rank: 3, l: 1, gf: 0, ga: 1),
            team("CRO", rank: 4, l: 1, gf: 0, ga: 2),
        ])]

        store.applyLiveScores(&groups, from: [liveMatch("FRA", 3, "MEX", 0)])
        let teams = groups[0].teams
        let fra = teams.first { $0.abbreviation == "FRA" }!
        let mex = teams.first { $0.abbreviation == "MEX" }!

        #expect(fra.gamesPlayed == 2)
        #expect(fra.points == 3)          // 0 → 3 after the live win
        #expect(fra.goalDiff == 2)        // -1 → +2
        #expect(fra.rank == 1)            // climbed 3 → 1
        #expect(mex.points == 3)          // unchanged points but…
        #expect(mex.rank == 3)            // …drops on goal difference
        #expect(fra.qualificationStatus == .direct)
        #expect(teams.first { $0.abbreviation == "CRO" }!.qualificationStatus == .eliminated)
    }

    // A live draw nudges both teams' points by one and counts the game.
    @Test func drawAwardsBothOnePoint() {
        let store = WorldCupStore()
        var groups = [group("A", [
            team("FRA", rank: 1, w: 1, gf: 2, ga: 1),
            team("MEX", rank: 2, d: 1, gf: 1, ga: 1),
        ])]

        store.applyLiveScores(&groups, from: [liveMatch("FRA", 1, "MEX", 1)])
        let fra = groups[0].teams.first { $0.abbreviation == "FRA" }!
        let mex = groups[0].teams.first { $0.abbreviation == "MEX" }!

        #expect(fra.points == 4)          // 3 + 1
        #expect(mex.points == 2)          // 1 + 1
        #expect(fra.draws == 1)
        #expect(mex.draws == 2)
        #expect(fra.gamesPlayed == 2)
        #expect(mex.gamesPlayed == 2)
    }

    // A knockout match (teams not in a shared group) must not touch any standings.
    @Test func knockoutMatchLeavesStandingsUntouched() {
        let store = WorldCupStore()
        var groups = [
            group("A", [team("FRA", rank: 1, w: 1, gf: 2, ga: 0)]),
            group("B", [team("BRA", rank: 1, w: 1, gf: 3, ga: 0)]),
        ]

        store.applyLiveScores(&groups, from: [liveMatch("FRA", 5, "BRA", 0)])
        let fra = groups[0].teams.first { $0.abbreviation == "FRA" }!
        let bra = groups[1].teams.first { $0.abbreviation == "BRA" }!

        #expect(fra.gamesPlayed == 1)     // no extra game counted
        #expect(fra.points == 3)
        #expect(bra.gamesPlayed == 1)
        #expect(bra.points == 3)
    }

    // With more than eight third-placed teams, only the best eight stay "in".
    @Test func bestThirdKeepsTopEight() {
        let store = WorldCupStore()
        // Nine groups; group i's third-place team has 9 - i points (group 0 strongest).
        var groups = (0..<9).map { i -> GroupStanding in
            group("G\(i)", [
                team("A\(i)", rank: 1, w: 3),
                team("B\(i)", rank: 2, w: 2),
                team("C\(i)", rank: 3, w: 0, d: max(0, 9 - i), gf: 9 - i, ga: 0),
                team("D\(i)", rank: 4, l: 3),
            ])
        }

        store.applyBestThirdCalculation(&groups)
        let thirds = groups.compactMap { g in g.teams.first { $0.rank == 3 } }

        let inCount = thirds.filter { $0.qualificationStatus == .bestThirdIn }.count
        let outCount = thirds.filter { $0.qualificationStatus == .bestThirdOut }.count
        #expect(inCount == 8)
        #expect(outCount == 1)
        // The weakest third-place team (group 8, fewest points) is the one left out.
        #expect(groups[8].teams.first { $0.rank == 3 }!.qualificationStatus == .bestThirdOut)
    }

    // Live state tags the two playing teams (winner/loser) and no one else.
    @Test func liveStateTagsPlayingTeams() {
        let store = WorldCupStore()
        var groups = [group("A", [
            team("ARG", rank: 1, w: 1, gf: 2, ga: 0),   // not playing this tick
            team("MEX", rank: 2, w: 1, gf: 1, ga: 0),
            team("FRA", rank: 3, l: 1, gf: 0, ga: 1),
            team("CRO", rank: 4, l: 1, gf: 0, ga: 2),
        ])]

        store.applyLiveScores(&groups, from: [liveMatch("FRA", 2, "MEX", 1)])
        let teams = groups[0].teams
        let fra = teams.first { $0.abbreviation == "FRA" }!
        let mex = teams.first { $0.abbreviation == "MEX" }!
        #expect(fra.liveState == .winning)
        #expect(mex.liveState == .losing)
        #expect(teams.first { $0.abbreviation == "ARG" }!.liveState == nil)
        #expect(teams.first { $0.abbreviation == "CRO" }!.liveState == nil)
        // Live scoreline is recorded from each team's own perspective.
        #expect(fra.liveScoreFor == 2 && fra.liveScoreAgainst == 1)
        #expect(mex.liveScoreFor == 1 && mex.liveScoreAgainst == 2)
        #expect(teams.first { $0.abbreviation == "ARG" }!.liveScoreFor == nil)
        // Match minute travels onto both playing rows (liveMatch is at 30').
        #expect(fra.liveClock == "30'" && mex.liveClock == "30'")
        #expect(teams.first { $0.abbreviation == "ARG" }!.liveClock == nil)
    }

    // A level live match flags both sides as drawing.
    @Test func liveStateMarksDraw() {
        let store = WorldCupStore()
        var groups = [group("A", [
            team("FRA", rank: 1, w: 1, gf: 2, ga: 1),
            team("MEX", rank: 2, d: 1, gf: 1, ga: 1),
        ])]

        store.applyLiveScores(&groups, from: [liveMatch("FRA", 1, "MEX", 1)])
        #expect(groups[0].teams.allSatisfy { $0.liveState == .drawing })
    }

    // A finished match must not leave a live highlight behind.
    @Test func finishedMatchClearsLiveState() {
        let store = WorldCupStore()
        var groups = [group("A", [
            team("FRA", rank: 1, w: 1, gf: 2, ga: 0),
            team("MEX", rank: 2, w: 1, gf: 1, ga: 0),
        ])]
        let finished = Match(
            id: "FRA-MEX",
            homeTeam: MatchTeam(abbreviation: "FRA", displayName: "FRA", score: 3),
            awayTeam: MatchTeam(abbreviation: "MEX", displayName: "MEX", score: 0),
            kickoff: Date(), status: .finished, minute: nil,
            groupName: "Group A", roundName: nil
        )

        store.applyLiveScores(&groups, from: [finished])
        #expect(groups[0].teams.allSatisfy { $0.liveState == nil })
    }

    // Before any team has kicked a ball, no third-place indicator should show.
    @Test func bestThirdHiddenBeforeKickoff() {
        let store = WorldCupStore()
        var groups = (0..<3).map { i in
            group("G\(i)", [
                team("A\(i)", rank: 1), team("B\(i)", rank: 2),
                team("C\(i)", rank: 3), team("D\(i)", rank: 4),
            ])
        }

        store.applyBestThirdCalculation(&groups)
        for g in groups {
            #expect(g.teams.first { $0.rank == 3 }!.qualificationStatus == .unknown)
        }
    }
}
