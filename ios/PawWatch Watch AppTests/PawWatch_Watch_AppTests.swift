//
//  PawWatch_Watch_AppTests.swift
//  PawWatch Watch AppTests
//
//  Created by Anchen Peng on 30/06/2026.
//

import Testing
@testable import PawWatch_Watch_App

struct PawWatch_Watch_AppTests {

    @Test func startsAtComoWithNoSteps() {
        let state = WatchState.from(steps: 0, authorized: true)

        #expect(state.city == "Como")
        #expect(state.nextCity == "Milan")
        #expect(state.remaining == 1000)
        #expect(state.progress == 0)
    }

    @Test func unlocksCityExactlyAtThreshold() {
        let state = WatchState.from(steps: 1000, authorized: true)

        #expect(state.city == "Milan")
        #expect(state.nextCity == "Turin")
        #expect(state.remaining == 3000)
        #expect(state.progress == 0)
    }

    @Test func calculatesProgressTowardNextCity() {
        let state = WatchState.from(steps: 2500, authorized: true)

        #expect(state.city == "Milan")
        #expect(state.nextCity == "Turin")
        #expect(state.remaining == 1500)
        #expect(state.progress == 0.5)
    }

    @Test func completesJourneyAtFinalCity() {
        let state = WatchState.from(steps: 70000, authorized: true)

        #expect(state.city == "Sardegna")
        #expect(state.nextCity.isEmpty)
        #expect(state.remaining == 0)
        #expect(state.progress == 1)
    }

}
