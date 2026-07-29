import XCTest
@testable import PlummetKinematics

final class ConflictTests: XCTestCase {
    func testConsistentOverInputIsSolved() {
        // v0=0,a=-9.81,t=2 implies s=-19.62,v=-19.62; supply s too, consistent.
        let r = KinematicsSolver.solve(KinematicsInput([.v0: 0, .a: -9.81, .t: 2, .s: -19.62]))
        if case .conflict = r { XCTFail("should be consistent") }
        guard case .solved = r else { return XCTFail("expected solved") }
    }

    func testConflictingOverInputFlagsRows() {
        // Same knowns but s wildly wrong (0 instead of -19.62) -> conflict.
        let r = KinematicsSolver.solve(KinematicsInput([.v0: 0, .a: -9.81, .t: 2, .s: 0]))
        guard case let .conflict(vars) = r else { return XCTFail("expected conflict") }
        XCTAssertTrue(vars.contains(.s))
    }
}
