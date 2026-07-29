import Foundation
import Combine

public enum FieldOrigin: Equatable {
    case empty, user, solved, conflicted
}

public final class SolverState: ObservableObject {
    @Published public var fields: [Variable: String]
    @Published public private(set) var origin: [Variable: FieldOrigin]
    @Published public private(set) var solved: [Variable: SolvedValue] = [:]
    @Published public private(set) var secondSolution: [Variable: Double]? = nil
    @Published public private(set) var elapsed: TimeInterval = 0
    @Published public private(set) var isTiming: Bool = false

    private let now: () -> TimeInterval
    private var startTime: TimeInterval = 0

    public init(now: @escaping () -> TimeInterval = { Date().timeIntervalSinceReferenceDate }) {
        self.now = now
        self.fields = [.a: "−9.81"]
        self.origin = [.a: .user, .s: .empty, .v0: .empty, .v: .empty, .t: .empty]
        recompute()
    }

    public func setField(_ v: Variable, to text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            fields[v] = nil
            origin[v] = .empty
        } else {
            fields[v] = trimmed
            origin[v] = .user
        }
        recompute()
    }

    public func reset() {
        fields = [.a: "−9.81"]
        origin = [.a: .user, .s: .empty, .v0: .empty, .v: .empty, .t: .empty]
        solved = [:]
        secondSolution = nil
        isTiming = false
        elapsed = 0
        recompute()
    }

    public func startStopwatch() {
        isTiming = true
        startTime = now()
        elapsed = 0
    }

    public func stopStopwatch() {
        guard isTiming else { return }
        isTiming = false
        elapsed = now() - startTime
        setField(.t, to: Formatting.number(elapsed, decimals: 2))
    }

    public func heightReadout() -> (meters: String, feet: String, floors: Int)? {
        guard let s = numericValue(.s) else { return nil }
        return Formatting.metersFeetFloors(fromDisplacement: s)
    }

    // MARK: - Internals

    private func numericValue(_ v: Variable) -> Double? {
        if let sv = solved[v] { return sv.value }
        return parse(fields[v])
    }

    private func parse(_ text: String?) -> Double? {
        guard let t = text?.replacingOccurrences(of: "−", with: "-") else { return nil }
        return Double(t)
    }

    private func recompute() {
        // Keep only user-entered fields as knowns.
        var knowns: [Variable: Double] = [:]
        for v in Variable.allCases where origin[v] == .user || origin[v] == .conflicted {
            if let d = parse(fields[v]) { knowns[v] = d }
        }
        let result = KinematicsSolver.solve(KinematicsInput(knowns))
        // Clear previous solved outputs.
        for v in Variable.allCases where origin[v] == .solved || origin[v] == .conflicted {
            if origin[v] == .solved { fields[v] = nil }
            origin[v] = (fields[v] == nil) ? .empty : .user
        }
        solved = [:]
        secondSolution = nil

        switch result {
        case .incomplete:
            break
        case let .solved(values, second):
            for (v, sv) in values {
                solved[v] = sv
                fields[v] = Formatting.number(sv.value)
                origin[v] = .solved
            }
            secondSolution = second
        case let .conflict(vars):
            for v in vars { origin[v] = .conflicted }
        case .noRealSolution:
            break
        }
    }
}
