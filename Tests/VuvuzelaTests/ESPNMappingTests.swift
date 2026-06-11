import Foundation
import Testing
@testable import VuvuzelaCore

// Mirrors the real site.api scoreboard payload shape: a top-level `events` array,
// each competition carrying a status `type` with a stable `state` bucket
// (pre / in / post) alongside soccer-specific `name`s like STATUS_FIRST_HALF.
private let sampleScoreboardJSON = """
{
  "events": [
    {
      "id": "1",
      "name": "Mexico vs South Africa",
      "date": "2026-06-11T19:00Z",
      "competitions": [
        {
          "status": {
            "clock": 840, "displayClock": "14'", "period": 1,
            "type": { "name": "STATUS_FIRST_HALF", "state": "in", "completed": false }
          },
          "competitors": [
            { "homeAway": "home", "team": {"id": "1", "abbreviation": "MEX", "displayName": "Mexico"}, "score": "1" },
            { "homeAway": "away", "team": {"id": "2", "abbreviation": "RSA", "displayName": "South Africa"}, "score": "0" }
          ]
        }
      ]
    },
    {
      "id": "2",
      "name": "Korea vs Czechia",
      "date": "2026-06-12T02:00Z",
      "competitions": [
        {
          "status": {
            "clock": 0, "displayClock": "45'", "period": 2,
            "type": { "name": "STATUS_HALFTIME", "state": "in", "completed": false }
          },
          "competitors": [
            { "homeAway": "home", "team": {"id": "3", "abbreviation": "KOR", "displayName": "Korea"}, "score": "0" },
            { "homeAway": "away", "team": {"id": "4", "abbreviation": "CZE", "displayName": "Czechia"}, "score": "1" }
          ]
        }
      ]
    },
    {
      "id": "3",
      "name": "Argentina vs France",
      "date": "2026-06-10T19:00Z",
      "competitions": [
        {
          "status": {
            "clock": 0, "displayClock": "90'+10", "period": 2,
            "type": { "name": "STATUS_FINAL_PEN", "state": "post", "completed": true }
          },
          "competitors": [
            { "homeAway": "home", "team": {"id": "5", "abbreviation": "ARG", "displayName": "Argentina"}, "score": "3" },
            { "homeAway": "away", "team": {"id": "6", "abbreviation": "FRA", "displayName": "France"}, "score": "3" }
          ]
        }
      ]
    },
    {
      "id": "4",
      "name": "Brazil vs Morocco",
      "date": "2026-06-14T01:00Z",
      "competitions": [
        {
          "status": {
            "clock": 0, "displayClock": "0'", "period": 0,
            "type": { "name": "STATUS_SCHEDULED", "state": "pre", "completed": false }
          },
          "competitors": [
            { "homeAway": "home", "team": {"id": "7", "abbreviation": "BRA", "displayName": "Brazil"}, "score": "0" },
            { "homeAway": "away", "team": {"id": "8", "abbreviation": "MAR", "displayName": "Morocco"}, "score": "0" }
          ]
        }
      ]
    }
  ]
}
""".data(using: .utf8)!

@Suite("ESPN site.api scoreboard mapping")
struct ESPNMappingTests {

    private func matches() throws -> [Match] {
        let decoded = try JSONDecoder().decode(ESPNSiteScoreboardResponse.self, from: sampleScoreboardJSON)
        return decoded.events?.compactMap { $0.toMatch() } ?? []
    }

    // A soccer first-half event must read as live — ESPN never sends STATUS_IN_PROGRESS
    // for soccer, so detection has to lean on the `state` bucket, not the exact name.
    @Test func firstHalfMapsToLive() throws {
        let mex = try matches().first { $0.homeTeam.abbreviation == "MEX" }!
        #expect(mex.status == .live)
        #expect(mex.isLive)
        #expect(mex.homeTeam.score == 1)
        #expect(mex.awayTeam.score == 0)
        #expect(mex.minute == 14)          // parsed from displayClock "14'"
    }

    @Test func halftimeMapsToHalftime() throws {
        let kor = try matches().first { $0.homeTeam.abbreviation == "KOR" }!
        #expect(kor.status == .halftime)
    }

    // Finished-after-penalties is still finished — must not fall through to .unknown.
    @Test func finalPenaltiesMapsToFinished() throws {
        let arg = try matches().first { $0.homeTeam.abbreviation == "ARG" }!
        #expect(arg.status == .finished)
        #expect(arg.isFinished)
    }

    @Test func scheduledStaysScheduled() throws {
        let bra = try matches().first { $0.homeTeam.abbreviation == "BRA" }!
        #expect(bra.status == .scheduled)
    }
}
