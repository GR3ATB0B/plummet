import XCTest
@testable import PlummetKinematics

final class SolverCoreTests: XCTestCase {
    func testFewerThanThreeKnownIsIncomplete() {
        let input = KinematicsInput([.a: -9.81, .v0: 0])
        XCTAssertEqual(KinematicsSolver.solve(input), .incomplete(knownCount: 2))
    }

    func testStandardGravityConstant() {
        XCTAssertEqual(standardGravity, -9.81, accuracy: 1e-9)
    }
}
