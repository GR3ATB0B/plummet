import XCTest
@testable import PlummetKinematics

final class EquationPrimitiveTests: XCTestCase {
    func testE1SolvesFinalVelocity() {
        // v = v0 + a t = 0 + (-9.81)(2) = -19.62
        let roots = Equation.e1.solve(for: .v, known: [.v0: 0, .a: -9.81, .t: 2])
        XCTAssertEqual(roots.count, 1)
        XCTAssertEqual(roots[0], -19.62, accuracy: 1e-9)
    }

    func testE2SolvesDisplacement() {
        // s = v0 t + 1/2 a t^2 = 0 + 0.5(-9.81)(4) = -19.62
        let roots = Equation.e2.solve(for: .s, known: [.v0: 0, .a: -9.81, .t: 2])
        XCTAssertEqual(roots.count, 1)
        XCTAssertEqual(roots[0], -19.62, accuracy: 1e-9)
    }

    func testE2SolvesTimeQuadraticTwoRoots() {
        // s = -19.62, v0 = 0, a = -9.81 -> 0.5(-9.81)t^2 = -19.62 -> t^2 = 4 -> t = ±2
        let roots = Equation.e2.solve(for: .t, known: [.s: -19.62, .v0: 0, .a: -9.81]).sorted()
        XCTAssertEqual(roots.count, 2)
        XCTAssertEqual(roots[0], -2, accuracy: 1e-6)
        XCTAssertEqual(roots[1], 2, accuracy: 1e-6)
    }

    func testE4SolvesFinalVelocityTwoRoots() {
        // v^2 = v0^2 + 2 a s = 0 + 2(-9.81)(-19.62) = 384.9444 -> v = ±19.62
        let roots = Equation.e4.solve(for: .v, known: [.v0: 0, .a: -9.81, .s: -19.62]).sorted()
        XCTAssertEqual(roots.count, 2)
        XCTAssertEqual(roots[0], -19.62, accuracy: 1e-5)
        XCTAssertEqual(roots[1], 19.62, accuracy: 1e-5)
    }

    func testE4NoRealSolutionReturnsEmpty() {
        // v^2 = v0^2 + 2 a s = 0 + 2(-9.81)(19.62) < 0 -> no real v
        let roots = Equation.e4.solve(for: .v, known: [.v0: 0, .a: -9.81, .s: 19.62])
        XCTAssertTrue(roots.isEmpty)
    }

    func testEquationOmittingMapping() {
        XCTAssertEqual(Equation.equationOmitting(.s), .e1)
        XCTAssertEqual(Equation.equationOmitting(.v), .e2)
        XCTAssertEqual(Equation.equationOmitting(.a), .e3)
        XCTAssertEqual(Equation.equationOmitting(.t), .e4)
        XCTAssertEqual(Equation.equationOmitting(.v0), .e5)
    }
}
