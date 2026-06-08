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

        // Final scripted scorelines.
        let fraMex = fixtures.first { $0.id == "demo-A-FRAMEX" }!
        let argCro = fixtures.first { $0.id == "demo-A-ARGCRO" }!
        #expect(fraMex.homeScore == 3 && fraMex.awayScore == 2)   // FRA 3-2 MEX
        #expect(argCro.homeScore == 2 && argCro.awayScore == 1)   // ARG 2-1 CRO
        #expect(fixtures.allSatisfy { $0.status == .finished })

        // Project the finished results onto the matchday-1 base standings.
        let matches = fixtures.map { $0.toMatch(kickoff: Date()) }
        var groups = base
        store.applyLiveScores(&groups, from: matches)
        let a = groups.first { $0.abbreviation == "A" }!.teams

        func t(_ abbr: String) -> TeamRow { a.first { $0.abbreviation == abbr }! }
        #expect(t("ARG").points == 6 && t("ARG").rank == 1)   // two wins → top
        #expect(t("FRA").points == 3)                          // lost md1, won md2
        #expect(t("MEX").points == 3)                          // won md1, lost md2
        #expect(t("CRO").points == 0 && t("CRO").rank == 4)   // two losses → bottom
        #expect(a.allSatisfy { $0.gamesPlayed == 2 })
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

        let espPor = fixtures.first { $0.id == "demo-B-ESPPOR" }!
        #expect(espPor.homeScore == 2 && espPor.awayScore == 1)   // ESP 2-1 POR

        let matches = fixtures.map { $0.toMatch(kickoff: Date()) }
        var groups = base
        store.applyLiveScores(&groups, from: matches)
        let esp = groups.first { $0.abbreviation == "B" }!.teams.first { $0.abbreviation == "ESP" }!
        #expect(esp.isFavorite)
        #expect(esp.points == 6)   // won both matchdays
    }

    // The favorite (Mexico) scores twice — the goals that should trigger alerts.
    @Test func favoriteScoresTwice() {
        var fixtures = DemoData.fixtures()
        var mexGoals = 0
        var prev = 0
        for minute in 1...90 {
            DemoData.apply(minute: minute, to: &fixtures)
            let mex = fixtures.first { $0.id == "demo-A-FRAMEX" }!.awayScore
            if mex > prev { mexGoals += 1 }
            prev = mex
        }
        #expect(DemoData.favorites.contains("MEX"))
        #expect(mexGoals == 2)
    }
}
