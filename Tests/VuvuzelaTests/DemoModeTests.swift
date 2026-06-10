import Foundation
import Testing
@testable import VuvuzelaCore

@MainActor
@Suite("Demo timeline")
struct DemoModeTests {

    // Runs the scripted demo minute-by-minute (no timer, no UI) and confirms the
    // final scores and the live-projected Group A table match the intended story.
    @Test func timelineProducesCoherentResults() {
        let store = WorldCupStore()
        let base = DemoData.baseGroups(favorites: DemoData.favorites)
        var fixtures = DemoData.fixtures()

        for minute in 1...90 {
            DemoData.apply(minute: minute, to: &fixtures)
        }

        // Final scripted scoreline for Group A's single live match.
        let mexFra = fixtures.first { $0.id == "demo-A" }!
        #expect(mexFra.homeScore == 3 && mexFra.awayScore == 1)   // MEX 3-1 FRA
        #expect(fixtures.allSatisfy { $0.status == .finished })

        // Project the finished results onto the matchday-1 base standings.
        let matches = fixtures.map { $0.toMatch(kickoff: Date()) }
        var groups = base
        store.applyLiveScores(&groups, from: matches)
        let a = groups.first { $0.abbreviation == "A" }!.teams

        func t(_ abbr: String) -> TeamRow { a.first { $0.abbreviation == abbr }! }
        #expect(t("MEX").points == 6 && t("MEX").rank == 1)   // won md1, won live → top
        #expect(t("FRA").points == 0 && t("FRA").rank == 4)   // lost md1, lost live → bottom
        #expect(t("ARG").points == 3)                          // won md1, no live match
        // Only the live match advances a game; the other two stay on matchday 1.
        #expect(t("MEX").gamesPlayed == 2 && t("FRA").gamesPlayed == 2)
        #expect(t("ARG").gamesPlayed == 1 && t("CRO").gamesPlayed == 1)
    }

    // The timeline passes through a half-time break and resumes for the 2nd half.
    @Test func timelineHasHalfTimeBreak() {
        var fixtures = DemoData.fixtures()
        var sawHalfTime = false
        var resumedAfter = false

        for minute in 1...90 {
            DemoData.apply(minute: minute, to: &fixtures)
            if minute == 46 { sawHalfTime = fixtures.allSatisfy { $0.status == .halftime } }
            if minute == 50 { resumedAfter = fixtures.allSatisfy { $0.status == .live } }
        }
        #expect(sawHalfTime)
        #expect(resumedAfter)
        #expect(fixtures.allSatisfy { $0.status == .finished })   // full time at the end
    }

    // Group B also has a live match with its favorite (Spain) in the action.
    @Test func groupBFavoriteAlsoPlays() {
        let store = WorldCupStore()
        let base = DemoData.baseGroups(favorites: DemoData.favorites)
        var fixtures = DemoData.fixtures()
        for minute in 1...90 { DemoData.apply(minute: minute, to: &fixtures) }

        let espBra = fixtures.first { $0.id == "demo-B" }!
        #expect(espBra.homeScore == 3 && espBra.awayScore == 0)   // ESP 3-0 BRA

        let matches = fixtures.map { $0.toMatch(kickoff: Date()) }
        var groups = base
        store.applyLiveScores(&groups, from: matches)
        let esp = groups.first { $0.abbreviation == "B" }!.teams.first { $0.abbreviation == "ESP" }!
        #expect(esp.isFavorite)
        #expect(esp.points == 6)   // won both matchdays
    }

    // The favorite (Mexico, now the home side) scores three times — the goals
    // that should trigger alerts.
    @Test func favoriteScoresThrice() {
        var fixtures = DemoData.fixtures()
        var mexGoals = 0
        var prev = 0
        for minute in 1...90 {
            DemoData.apply(minute: minute, to: &fixtures)
            let mex = fixtures.first { $0.id == "demo-A" }!.homeScore
            if mex > prev { mexGoals += 1 }
            prev = mex
        }
        #expect(DemoData.favorites.contains("MEX"))
        #expect(mexGoals == 3)
    }
}
