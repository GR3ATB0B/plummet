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
                Spacer()
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
