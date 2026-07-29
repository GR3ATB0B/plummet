import XCTest
@testable import PlummetKinematics

final class SolverWiringTests: XCTestCase {
    func testGravityConstant() {
        XCTAssertEqual(Kinematics.gravity(), -9.81, accuracy: 1e-9)
    }
}
