import XCTest
@testable import PlummetKinematics

final class PhysicsCasesTests: XCTestCase {
    private func vals(_ r: SolveResult) -> [Variable: SolvedValue] {
        guard case let .solved(v, _) = r else { return [:] }
        return v
    }

    func testThrowDownInitialSpeed() {
        // Thrown down v0 = -5, a = -9.81, t = 1 -> v = -14.81, s = -9.905
        let v = vals(KinematicsSolver.solve(KinematicsInput([.v0: -5, .a: -9.81, .t: 1])))
        XCTAssertEqual(v[.v]?.value ?? .nan, -14.81, accuracy: 1e-6)
        XCTAssertEqual(v[.s]?.value ?? .nan, -9.905, accuracy: 1e-6)
    }

    func testKnownSVTSolvesV0AndA() {
        // s = 10, v = 8, t = 2 (a unknown, v0 unknown)
        // e3 (omit a) solve v0: 2s/t - v = 10 - 8 = 2 ; e1? a from e-omit v0 = e5 solve a
        let v = vals(KinematicsSolver.solve(KinematicsInput([.s: 10, .v: 8, .t: 2])))
        XCTAssertEqual(v[.v0]?.value ?? .nan, 2, accuracy: 1e-9)
        // v = v0 + a t -> 8 = 2 + a*2 -> a = 3
        XCTAssertEqual(v[.a]?.value ?? .nan, 3, accuracy: 1e-9)
    }

    func testKnownV0VASolvesSAndT() {
        // v0 = 0, v = -19.62, a = -9.81 -> t = 2, s = -19.62
        let v = vals(KinematicsSolver.solve(KinematicsInput([.v0: 0, .v: -19.62, .a: -9.81])))
        XCTAssertEqual(v[.t]?.value ?? .nan, 2, accuracy: 1e-5)
        XCTAssertEqual(v[.s]?.value ?? .nan, -19.62, accuracy: 1e-4)
    }

    func testThrowUpPassesHeightTwiceHasSecondSolution() {
        // v0 = 19.62 up, a = -9.81, s = 14.715 (below apex 19.62). Two times.
        let r = KinematicsSolver.solve(KinematicsInput([.v0: 19.62, .a: -9.81, .s: 14.715]))
        guard case let .solved(values, second) = r else { return XCTFail("expected solved") }
        let t1 = values[.t]?.value ?? .nan
        let t2 = second?[.t] ?? .nan
        XCTAssertGreaterThanOrEqual(t1, 0)
        XCTAssertNotNil(second?[.t])
        // primary is the earlier (smaller) positive time
        XCTAssertLessThan(t1, t2)
    }

    func testMoonGravityEditable() {
        // a = -1.62 (Moon), v0 = 0, t = 2 -> s = -3.24
        let v = vals(KinematicsSolver.solve(KinematicsInput([.v0: 0, .a: -1.62, .t: 2])))
        XCTAssertEqual(v[.s]?.value ?? .nan, -3.24, accuracy: 1e-6)
    }
}
