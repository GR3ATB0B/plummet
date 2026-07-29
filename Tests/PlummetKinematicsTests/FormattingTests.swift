import XCTest
@testable import PlummetKinematics

final class FormattingTests: XCTestCase {
    func testNumberRoundsAndTrims() {
        XCTAssertEqual(Formatting.number(19.6200001), "19.62")
        XCTAssertEqual(Formatting.number(2.0), "2")
        XCTAssertEqual(Formatting.number(-19.62), "−19.62")
    }

    func testMetersFeetFloorsUsesMagnitude() {
        let r = Formatting.metersFeetFloors(fromDisplacement: -22.5)
        XCTAssertEqual(r.meters, "22.5")
        XCTAssertEqual(r.feet, "73.8") // 22.5 m * 3.28084
        XCTAssertEqual(r.floors, 8)     // round(22.5 / 3) = 8 (7.5 -> 8)
    }

    func testSubstitutionPlugsNumbers() {
        // e2 solving s with v0=0, a=-9.81, t=2
        let s = Formatting.substitution(.e2, for: .s, known: [.v0: 0, .a: -9.81, .t: 2])
        XCTAssertEqual(s, "s = 0·2 + ½·(−9.81)·2²")
    }

    func testSubstitutionKeepsTargetSymbolic() {
        // Solving t via e2 with s, v0, a known: target t stays symbolic, knowns numeric.
        let s = Formatting.substitution(.e2, for: .t, known: [.s: -19.62, .v0: 0, .a: -9.81])
        XCTAssertEqual(s, "(−19.62) = 0·t + ½·(−9.81)·t²")
    }
}
