import XCTest
@testable import PlummetKinematics

final class SolverStateTests: XCTestCase {
    func testDefaultsHaveGravityOnly() {
        let s = SolverState()
        XCTAssertEqual(s.fields[.a], "−9.81")
        XCTAssertNil(s.solved[.s])
    }

    func testEnteringTwoMoreSolves() {
        let s = SolverState()
        s.setField(.v0, to: "0")
        s.setField(.t, to: "2")
        XCTAssertEqual(s.origin[.s], .solved)
        XCTAssertEqual(s.solved[.s]?.value ?? .nan, -19.62, accuracy: 1e-6)
    }

    func testHeightReadoutMagnitude() {
        let s = SolverState()
        s.setField(.v0, to: "0")
        s.setField(.t, to: "2")
        let r = s.heightReadout()
        XCTAssertEqual(r?.meters, "19.62")
        XCTAssertEqual(r?.floors, 7) // round(19.62/3)=7 (6.54 -> 7)
    }

    func testStopwatchWritesTimeAndSolves() {
        var clock: TimeInterval = 100
        let s = SolverState(now: { clock })
        s.setField(.v0, to: "0")   // one known besides gravity
        s.startStopwatch()          // t0 = 100
        clock = 103                 // 3 seconds later
        s.stopStopwatch()           // writes t = 3
        XCTAssertEqual(s.fields[.t], "3")
        XCTAssertEqual(s.solved[.s]?.value ?? .nan, -44.145, accuracy: 1e-3) // 0.5*-9.81*9
    }

    func testResetClearsButKeepsGravity() {
        let s = SolverState()
        s.setField(.v0, to: "0"); s.setField(.t, to: "2")
        s.reset()
        XCTAssertEqual(s.fields[.a], "−9.81")
        XCTAssertNil(s.fields[.t])
        XCTAssertNil(s.solved[.s])
    }

    func testConflictMarksOrigin() {
        let s = SolverState()
        s.setField(.v0, to: "0"); s.setField(.t, to: "2"); s.setField(.s, to: "0")
        XCTAssertEqual(s.origin[.s], .conflicted)
    }

    func testResetClearsStopwatch() {
        var clock: TimeInterval = 50
        let s = SolverState(now: { clock })
        s.startStopwatch()
        clock = 53
        s.reset()
        XCTAssertFalse(s.isTiming)
        XCTAssertEqual(s.elapsed, 0)
    }
}
