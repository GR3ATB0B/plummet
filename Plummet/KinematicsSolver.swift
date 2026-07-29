import Foundation

public let standardGravity = -9.81

public enum Variable: CaseIterable, Hashable {
    case s, v0, v, a, t
}

public struct KinematicsInput: Equatable {
    public var values: [Variable: Double]
    public init(_ values: [Variable: Double]) { self.values = values }
    public var known: Set<Variable> { Set(values.keys) }
}

public struct SolvedValue: Equatable {
    public let value: Double
    public let equation: String
    public let substitution: String
    public init(value: Double, equation: String, substitution: String) {
        self.value = value
        self.equation = equation
        self.substitution = substitution
    }
}

public enum SolveResult: Equatable {
    case incomplete(knownCount: Int)
    case solved(values: [Variable: SolvedValue], secondSolution: [Variable: Double]?)
    case conflict(Set<Variable>)
    case noRealSolution
}

public enum KinematicsSolver {
    public static func solve(_ input: KinematicsInput) -> SolveResult {
        let known = input.known
        if known.count < 3 {
            return .incomplete(knownCount: known.count)
        }
        return .incomplete(knownCount: known.count) // replaced in Task 2+
    }
}
