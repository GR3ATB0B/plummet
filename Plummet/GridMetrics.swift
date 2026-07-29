import SwiftUI

enum GridMetrics {
    /// The graph square — the layout unit. Every vertical measurement is a multiple of this.
    static let square: CGFloat = 22

    static let paper = Color(red: 0.984, green: 0.984, blue: 0.953)      // #FBFBF3
    static let line = Color(red: 0.894, green: 0.906, blue: 0.847)       // #E4E7D8
    static let ink = Color(red: 0.173, green: 0.173, blue: 0.165)        // #2C2C2A
    static let inkGreen = Color(red: 0.09, green: 0.204, blue: 0.016)    // #173404
    static let inkGreenSoft = Color(red: 0.231, green: 0.427, blue: 0.067) // #3B6D11
    static let pencil = Color(red: 0.533, green: 0.529, blue: 0.505)     // #888780

    static let mono = Font.system(.body, design: .monospaced)

    /// Rounds a height to a whole number of squares.
    static func squares(_ n: CGFloat) -> CGFloat { n * square }
}

struct GraphPaper: View {
    var body: some View {
        Canvas { context, size in
            let step = GridMetrics.square
            var x: CGFloat = 0
            while x <= size.width {
                var p = Path()
                p.move(to: CGPoint(x: x, y: 0))
                p.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(p, with: .color(GridMetrics.line), lineWidth: 1)
                x += step
            }
            var y: CGFloat = 0
            while y <= size.height {
                var p = Path()
                p.move(to: CGPoint(x: 0, y: y))
                p.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(p, with: .color(GridMetrics.line), lineWidth: 1)
                y += step
            }
        }
        .background(GridMetrics.paper)
        .ignoresSafeArea()
    }
}
