import XCTest
@testable import PlummetKinematics

final class SolveDispatchTests: XCTestCase {
    private func solved(_ r: SolveResult) -> [Variable: SolvedValue] {
        guard case let .solved(values, _) = r else { return [:] }
        return values
    }

    func testDropFromRestSolvesHeightAndFinalVelocity() {
        // Known: v0 = 0, a = -9.81, t = 2  ->  s = -19.62, v = -19.62
        let r = KinematicsSolver.solve(KinematicsInput([.v0: 0, .a: -9.81, .t: 2]))
        let v = solved(r)
        XCTAssertEqual(v[.s]?.value ?? .nan, -19.62, accuracy: 1e-6)
        XCTAssertEqual(v[.v]?.value ?? .nan, -19.62, accuracy: 1e-6)
    }

    func testDropGivenHeightSolvesTimePositive() {
        // Known: s = -19.62, v0 = 0, a = -9.81 -> t = 2 (primary, positive), v = -19.62
        let r = KinematicsSolver.solve(KinematicsInput([.s: -19.62, .v0: 0, .a: -9.81]))
        guard case let .solved(values, second) = r else { return XCTFail("expected solved") }
        XCTAssertEqual(values[.t]?.value ?? .nan, 2, accuracy: 1e-5)
        // A second (negative-time) root exists mathematically; primary must be the positive one.
        XCTAssertNotNil(second?[.t])
        XCTAssertEqual(second?[.t] ?? .nan, -2, accuracy: 1e-5)
    }

    func testThrowUpApexHeight() {
        // Thrown up at v0 = 19.62, at apex v = 0, a = -9.81 -> s = 19.62 (up), t = 2
        let r = KinematicsSolver.solve(KinematicsInput([.v0: 19.62, .v: 0, .a: -9.81]))
        let v = solved(r)
        XCTAssertEqual(v[.s]?.value ?? .nan, 19.62, accuracy: 1e-5)
        XCTAssertEqual(v[.t]?.value ?? .nan, 2, accuracy: 1e-5)
    }

    func testEquationRecordedForSolvedVariable() {
        let r = KinematicsSolver.solve(KinematicsInput([.v0: 0, .a: -9.81, .t: 2]))
        XCTAssertEqual(solved(r)[.s]?.equation, "s = v₀·t + ½·a·t²")
    }

    func testNoRealSolution() {
        // Known v = 0, v0 = 0, but require them to differ via a,s inconsistent sqrt:
        // v0 solved from e4 with v=0,a=-9.81,s=19.62 -> v0^2 = 0 - 2(-9.81)(19.62) ... = +384 ok.
        // Force no-real: solve v from v0=5, a=-9.81, s=100 (up 100m started 5 m/s -> can't reach) -> negative under root
        let r = KinematicsSolver.solve(KinematicsInput([.v0: 5, .a: -9.81, .s: 100]))
        XCTAssertEqual(r, .noRealSolution)
    }
}
