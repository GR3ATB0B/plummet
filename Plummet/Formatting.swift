import Foundation

public enum Formatting {
    public static func number(_ v: Double, decimals: Int = 2) -> String {
        if v.isNaN { return "—" }
        let rounded = (v * pow(10, Double(decimals))).rounded() / pow(10, Double(decimals))
        let normalized = rounded == 0 ? 0 : rounded // avoid "-0"
        var s = String(format: "%.\(decimals)f", normalized)
        if s.contains(".") {
            while s.hasSuffix("0") { s.removeLast() }
            if s.hasSuffix(".") { s.removeLast() }
        }
        return s.replacingOccurrences(of: "-", with: "−")
    }

    public static func metersFeetFloors(fromDisplacement s: Double) -> (meters: String, feet: String, floors: Int) {
        let mag = abs(s)
        let feet = mag * 3.28084
        let floors = Int((mag / 3.0).rounded())
        return (number(mag, decimals: 2), number(feet, decimals: 1), floors)
    }

    static func substitution(_ eq: Equation, for target: Variable, known k: [Variable: Double]) -> String {
        func term(_ v: Variable) -> String {
            if v == target { return symbol(v) }
            let value = k[v] ?? .nan
            let s = number(value)
            return value < 0 ? "(\(s))" : s
        }
        switch eq {
        case .e1: return "\(term(.v)) = \(term(.v0)) + \(term(.a))·\(term(.t))"
        case .e2: return "\(term(.s)) = \(term(.v0))·\(term(.t)) + ½·\(term(.a))·\(term(.t))²"
        case .e3: return "\(term(.s)) = ½·(\(term(.v0)) + \(term(.v)))·\(term(.t))"
        case .e4: return "\(term(.v))² = \(term(.v0))² + 2·\(term(.a))·\(term(.s))"
        case .e5: return "\(term(.s)) = \(term(.v))·\(term(.t)) − ½·\(term(.a))·\(term(.t))²"
        }
    }

    static func symbol(_ v: Variable) -> String {
        switch v {
        case .s: return "s"
        case .v0: return "v₀"
        case .v: return "v"
        case .a: return "a"
        case .t: return "t"
        }
    }
}
