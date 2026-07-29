import SwiftUI

struct NotebookView: View {
    @StateObject private var state = SolverState()

    var body: some View {
        ZStack(alignment: .topLeading) {
            GraphPaper()
            VStack(alignment: .leading, spacing: 0) {
                titleBlock
                    .padding(.bottom, GridMetrics.square)
                ForEach([Variable.s, .v0, .v, .a, .t], id: \.self) { v in
                    FieldRowView(variable: v, state: state)
                }
                if let second = state.secondSolution, let t2 = second[.t] {
                    Text("▸ 2nd solution: t = \(Formatting.number(t2)) s")
                        .font(.system(.footnote, design: .monospaced))
                        .foregroundStyle(GridMetrics.pencil)
                        .frame(height: GridMetrics.square, alignment: .bottom)
                }
                if let h = state.heightReadout() {
                    Text("│s│ = \(h.meters) m  ·  \(h.feet) ft  ·  ≈ \(h.floors) floors")
                        .font(.system(.footnote, design: .monospaced))
                        .foregroundStyle(GridMetrics.inkGreenSoft)
                        .frame(height: GridMetrics.square, alignment: .bottom)
                }
                Spacer(minLength: GridMetrics.square)
                HStack {
                    Button {
                        state.reset()
                        Haptics.tap()
                    } label: {
                        Text("⌫ reset")
                            .font(.system(.footnote, design: .monospaced))
                            .foregroundStyle(GridMetrics.pencil)
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
                .frame(height: GridMetrics.square * 2)
                StopwatchBar(state: state)
            }
            .padding(.horizontal, GridMetrics.square)
            .padding(.top, GridMetrics.square * 3)
        }
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Plummet")
                .font(.system(size: 30, weight: .regular, design: .monospaced))
                .foregroundStyle(GridMetrics.ink)
                .frame(height: GridMetrics.square * 2, alignment: .bottom)
            Text("↑ +   ·   a = −9.81 m/s²")
                .font(.system(.footnote, design: .monospaced))
                .foregroundStyle(GridMetrics.pencil)
                .frame(height: GridMetrics.square, alignment: .bottom)
        }
    }
}
