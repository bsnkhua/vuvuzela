import Foundation
import Testing
@testable import VuvuzelaCore

@MainActor
@Suite("Polling schedule")
struct PollingTests {

    // Regression: start() scheduled the first tick from pre-fetch (empty) state —
    // a 1-hour interval — and refresh() never re-timed the poll afterwards, so
    // during live matches the app fetched once and then went silent for an hour.
    // Every completed refresh must reschedule the next poll from fresh state.
    @Test func completedRefreshReschedulesNextPoll() async {
        let store = WorldCupStore()
        store.timer?.invalidate()
        store.timer = nil

        await store.refresh()   // success or network error — either way it completes

        #expect(store.timer != nil, "refresh() must re-time the next poll")
    }

    // Regression: when the last live match ended, computeInterval() jumped straight
    // to the 1-hour idle cadence. ESPN's standings endpoint settles a few minutes
    // AFTER the final whistle, so the table stayed stale until the next hourly poll
    // (or a manual "Refresh Now"). A recently-finished match must keep a fast poll.
    @Test func recentlyFinishedMatchKeepsFastCadence() {
        let store = WorldCupStore()
        store.recentFinishDeadline = Date().addingTimeInterval(600)
        #expect(store.computeInterval() == 120)
    }

    @Test func idleStateUsesHourlyCadence() {
        let store = WorldCupStore()
        store.recentFinishDeadline = nil
        #expect(store.computeInterval() == 3600)
    }
}
