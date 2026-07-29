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
        if known.count > 3 {
            return solveOverdetermined(input) // Task 5 replaces; temporary passthrough below
        }
        return solveExactlyThree(input)
    }

    // Temporary until Task 5; treat >3 as "trust first 3" is wrong — Task 5 implements properly.
    static func solveOverdetermined(_ input: KinematicsInput) -> SolveResult {
        return .incomplete(knownCount: input.known.count)
    }

    static func solveExactlyThree(_ input: KinematicsInput) -> SolveResult {
        let all = Set(Variable.allCases)
        let unknowns = Array(all.subtracting(input.known))
        guard unknowns.count == 2 else { return .incomplete(knownCount: input.known.count) }
        let u = unknowns[0], w = unknowns[1]

        // Solve u using the equation that omits w (so it contains the 3 knowns + u).
        let uRoots = Equation.equationOmitting(w).solve(for: u, known: input.values).filter { !$0.isNaN }
        if uRoots.isEmpty { return .noRealSolution }

        // For each candidate u-root, solve w using the equation that omits u.
        var candidates: [(uVal: Double, wVal: Double)] = []
        for uVal in uRoots {
            var k = input.values
            k[u] = uVal
            let wRoots = Equation.equationOmitting(u).solve(for: w, known: k).filter { !$0.isNaN }
            for wVal in wRoots { candidates.append((uVal, wVal)) }
        }
        if candidates.isEmpty { return .noRealSolution }

        let primary = pickPrimary(candidates, u: u, w: w)
        let uEq = Equation.equationOmitting(w)
        let wEq = Equation.equationOmitting(u)
        let values: [Variable: SolvedValue] = [
            u: SolvedValue(value: primary.uVal, equation: uEq.displayString, substitution: uEq.displayString),
            w: SolvedValue(value: primary.wVal, equation: wEq.displayString, substitution: wEq.displayString),
        ]

        // Second solution: a distinct candidate (different primary unknown value).
        var second: [Variable: Double]? = nil
        if let alt = candidates.first(where: { !approxEqual($0.uVal, primary.uVal) || !approxEqual($0.wVal, primary.wVal) }) {
            second = [u: alt.uVal, w: alt.wVal]
        }
        return .solved(values: values, secondSolution: second)
    }

    /// Prefer solutions with non-negative time; among those the smallest time; else the original order.
    static func pickPrimary(_ cands: [(uVal: Double, wVal: Double)], u: Variable, w: Variable) -> (uVal: Double, wVal: Double) {
        func timeOf(_ c: (uVal: Double, wVal: Double)) -> Double? {
            if u == .t { return c.uVal }
            if w == .t { return c.wVal }
            return nil
        }
        if timeOf(cands[0]) != nil {
            let nonNeg = cands.filter { (timeOf($0) ?? -1) >= 0 }
            if let best = nonNeg.min(by: { (timeOf($0) ?? .infinity) < (timeOf($1) ?? .infinity) }) {
                return best
            }
        }
        return cands[0]
    }

    static func approxEqual(_ a: Double, _ b: Double) -> Bool { abs(a - b) < 1e-9 }
}

enum Equation: CaseIterable {
    case e1, e2, e3, e4, e5

    var omits: Variable {
        switch self {
        case .e1: return .s
        case .e2: return .v
        case .e3: return .a
        case .e4: return .t
        case .e5: return .v0
        }
    }

    var displayString: String {
        switch self {
        case .e1: return "v = v₀ + a·t"
        case .e2: return "s = v₀·t + ½·a·t²"
        case .e3: return "s = ½·(v₀ + v)·t"
        case .e4: return "v² = v₀² + 2·a·s"
        case .e5: return "s = v·t − ½·a·t²"
        }
    }

    static func equationOmitting(_ v: Variable) -> Equation {
        switch v {
        case .s: return .e1
        case .v: return .e2
        case .a: return .e3
        case .t: return .e4
        case .v0: return .e5
        }
    }

    private static let epsilon = 1e-12

    /// Real roots for `target`, or [] when no real solution / degenerate.
    func solve(for target: Variable, known k: [Variable: Double]) -> [Double] {
        func g(_ v: Variable) -> Double { k[v] ?? .nan }
        switch (self, target) {

        // e1: v = v0 + a t
        case (.e1, .v):  return [g(.v0) + g(.a) * g(.t)]
        case (.e1, .v0): return [g(.v) - g(.a) * g(.t)]
        case (.e1, .a):  return abs(g(.t)) < Self.epsilon ? [] : [(g(.v) - g(.v0)) / g(.t)]
        case (.e1, .t):  return abs(g(.a)) < Self.epsilon ? [] : [(g(.v) - g(.v0)) / g(.a)]

        // e2: s = v0 t + 1/2 a t^2
        case (.e2, .s):  return [g(.v0) * g(.t) + 0.5 * g(.a) * g(.t) * g(.t)]
        case (.e2, .v0): return abs(g(.t)) < Self.epsilon ? [] : [(g(.s) - 0.5 * g(.a) * g(.t) * g(.t)) / g(.t)]
        case (.e2, .a):  return abs(g(.t)) < Self.epsilon ? [] : [2 * (g(.s) - g(.v0) * g(.t)) / (g(.t) * g(.t))]
        case (.e2, .t):  return Self.quadraticRoots(a: 0.5 * g(.a), b: g(.v0), c: -g(.s))

        // e3: s = 1/2 (v0 + v) t
        case (.e3, .s):  return [0.5 * (g(.v0) + g(.v)) * g(.t)]
        case (.e3, .v0): return abs(g(.t)) < Self.epsilon ? [] : [2 * g(.s) / g(.t) - g(.v)]
        case (.e3, .v):  return abs(g(.t)) < Self.epsilon ? [] : [2 * g(.s) / g(.t) - g(.v0)]
        case (.e3, .t):
            let sum = g(.v0) + g(.v)
            return abs(sum) < Self.epsilon ? [] : [2 * g(.s) / sum]

        // e4: v^2 = v0^2 + 2 a s
        case (.e4, .s):  return abs(g(.a)) < Self.epsilon ? [] : [(g(.v) * g(.v) - g(.v0) * g(.v0)) / (2 * g(.a))]
        case (.e4, .a):  return abs(g(.s)) < Self.epsilon ? [] : [(g(.v) * g(.v) - g(.v0) * g(.v0)) / (2 * g(.s))]
        case (.e4, .v):  return Self.plusMinusSqrt(g(.v0) * g(.v0) + 2 * g(.a) * g(.s))
        case (.e4, .v0): return Self.plusMinusSqrt(g(.v) * g(.v) - 2 * g(.a) * g(.s))

        // e5: s = v t - 1/2 a t^2
        case (.e5, .s):  return [g(.v) * g(.t) - 0.5 * g(.a) * g(.t) * g(.t)]
        case (.e5, .v):  return abs(g(.t)) < Self.epsilon ? [] : [(g(.s) + 0.5 * g(.a) * g(.t) * g(.t)) / g(.t)]
        case (.e5, .a):  return abs(g(.t)) < Self.epsilon ? [] : [2 * (g(.v) * g(.t) - g(.s)) / (g(.t) * g(.t))]
        case (.e5, .t):  return Self.quadraticRoots(a: -0.5 * g(.a), b: g(.v), c: -g(.s))

        default: return []
        }
    }

    /// Roots of a x^2 + b x + c = 0. Falls back to linear when a ≈ 0.
    static func quadraticRoots(a: Double, b: Double, c: Double) -> [Double] {
        if abs(a) < epsilon {
            if abs(b) < epsilon { return [] }
            return [-c / b]
        }
        let disc = b * b - 4 * a * c
        if disc < 0 { return [] }
        if disc == 0 { return [-b / (2 * a)] }
        let sq = disc.squareRoot()
        return [(-b + sq) / (2 * a), (-b - sq) / (2 * a)]
    }

    static func plusMinusSqrt(_ value: Double) -> [Double] {
        if value < 0 { return [] }
        if value == 0 { return [0] }
        let r = value.squareRoot()
        return [r, -r]
    }
}
