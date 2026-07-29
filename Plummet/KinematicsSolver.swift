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

    static func solveOverdetermined(_ input: KinematicsInput) -> SolveResult {
        // Trust knowns in this priority order; try 3-subsets in that order (canonical
        // = first three) until one actually solves. Falling back to an alternate subset
        // rescues cases where the canonical trio is degenerate (e.g. a == 0).
        let priority: [Variable] = [.a, .t, .v0, .v, .s]
        let knownOrdered = priority.filter { input.known.contains($0) }
        for subset in combinations(knownOrdered, choose: 3) {
            var trimmed: [Variable: Double] = [:]
            for v in subset { trimmed[v] = input.values[v] }

            let base = solveExactlyThree(KinematicsInput(trimmed))
            guard case let .solved(values, _) = base else { continue }

            var predicted = trimmed
            for (k, sv) in values { predicted[k] = sv.value }

            var conflicts: Set<Variable> = []
            for v in input.known where !subset.contains(v) {
                let supplied = input.values[v]!
                let expected = predicted[v] ?? .nan
                let tol = max(1e-4, abs(expected) * 1e-4)
                if abs(supplied - expected) > tol { conflicts.insert(v) }
            }
            if !conflicts.isEmpty { return .conflict(conflicts) }
            return .solved(values: values, secondSolution: nil)
        }
        return .noRealSolution
    }

    /// All k-length combinations of `arr`, preserving input order (so the first
    /// combination is the first `k` elements — the canonical trusted subset).
    static func combinations(_ arr: [Variable], choose k: Int) -> [[Variable]] {
        guard k > 0 else { return [[]] }
        guard arr.count >= k else { return [] }
        if arr.count == k { return [arr] }
        let first = arr[0]
        let rest = Array(arr.dropFirst())
        return combinations(rest, choose: k - 1).map { [first] + $0 } + combinations(rest, choose: k)
    }

    private struct Candidate { let uVal: Double; let wVal: Double; let wEq: Equation }

    static func solveExactlyThree(_ input: KinematicsInput) -> SolveResult {
        let all = Set(Variable.allCases)
        let originalKnown = input.known
        let unknowns = Array(all.subtracting(originalKnown))
        guard unknowns.count == 2 else { return .incomplete(knownCount: input.known.count) }

        // Deterministic driver `u`: prefer time (legitimately two-valued), else earliest in allCases.
        let u: Variable
        let w: Variable
        if unknowns.contains(.t) {
            u = .t
            w = unknowns.first { $0 != .t }!
        } else {
            let ordered = Variable.allCases.filter { unknowns.contains($0) }
            u = ordered[0]; w = ordered[1]
        }

        // Solve u from the 3 original knowns (equation that omits w = exactly the 3 knowns + u).
        let uEq = Equation.equationOmitting(w)
        let uRoots = uEq.solve(for: u, known: input.values).filter { !$0.isNaN }
        if uRoots.isEmpty { return .noRealSolution }

        // For each u root, solve w with a LINKING equation that references u so each
        // (u, w) pair is mutually consistent. An equation that omits one ORIGINAL known
        // contains both u and w.
        var candidates: [Candidate] = []
        for uVal in uRoots {
            var k = input.values
            k[u] = uVal
            for omit in Variable.allCases where originalKnown.contains(omit) {
                let eq = Equation.equationOmitting(omit)
                if let wVal = eq.solve(for: w, known: k).filter({ !$0.isNaN }).first {
                    candidates.append(Candidate(uVal: uVal, wVal: wVal, wEq: eq))
                    break
                }
            }
        }
        if candidates.isEmpty { return .noRealSolution }

        let primary = pickPrimary(candidates, driver: u)
        let values: [Variable: SolvedValue] = [
            u: SolvedValue(value: primary.uVal, equation: uEq.displayString,
                           substitution: Formatting.substitution(uEq, for: u, known: withKnowns(input.values, u, primary.uVal, w, primary.wVal))),
            w: SolvedValue(value: primary.wVal, equation: primary.wEq.displayString,
                           substitution: Formatting.substitution(primary.wEq, for: w, known: withKnowns(input.values, u, primary.uVal, w, primary.wVal))),
        ]

        var second: [Variable: Double]? = nil
        if let alt = candidates.first(where: { !approxEqual($0.uVal, primary.uVal) || !approxEqual($0.wVal, primary.wVal) }) {
            second = [u: alt.uVal, w: alt.wVal]
        }
        return .solved(values: values, secondSolution: second)
    }

    /// Prefer non-negative time, smallest, when the driver is time; else the first candidate.
    private static func pickPrimary(_ cands: [Candidate], driver: Variable) -> Candidate {
        if driver == .t {
            if let best = cands.filter({ $0.uVal >= 0 }).min(by: { $0.uVal < $1.uVal }) { return best }
        }
        return cands[0]
    }

    static func approxEqual(_ a: Double, _ b: Double) -> Bool { abs(a - b) < 1e-9 }

    static func withKnowns(_ base: [Variable: Double], _ a: Variable, _ av: Double, _ b: Variable, _ bv: Double) -> [Variable: Double] {
        var k = base; k[a] = av; k[b] = bv; return k
    }
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
