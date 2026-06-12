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
}
