import SwiftUI

struct NotebookView: View {
    @StateObject private var state = SolverState()
    @State private var countdown: Int? = nil

    var body: some View {
        ZStack(alignment: .topLeading) {
            GraphPaper()
                .onTapGesture { dismissKeyboard() }
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
                    Button {
                        startCountdown()
                    } label: {
                        Text("▷ 3·2·1 drop")
                            .font(.system(size: 15, design: .monospaced))
                            .foregroundStyle(GridMetrics.inkGreen)
                            .padding(.horizontal, GridMetrics.square)
                            .frame(height: GridMetrics.square * 2)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(GridMetrics.inkGreen, lineWidth: 1.5)
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(countdown != nil || state.isTiming)
                    .opacity((countdown != nil || state.isTiming) ? 0.4 : 1)
                }
                .frame(height: GridMetrics.square * 2)
                StopwatchBar(state: state)
            }
            .padding(.horizontal, GridMetrics.square)
            .padding(.top, GridMetrics.square * 3)
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { dismissKeyboard() }
            }
        }
        .overlay { countdownOverlay }
    }

    @ViewBuilder
    private var countdownOverlay: some View {
        if let c = countdown {
            ZStack {
                GridMetrics.paper.opacity(0.94).ignoresSafeArea()
                Text(c == 0 ? "GO" : "\(c)")
                    .font(.system(size: c == 0 ? 150 : 240, weight: .regular, design: .monospaced))
                    .foregroundStyle(c == 0 ? GridMetrics.inkGreen : GridMetrics.ink)
            }
            .allowsHitTesting(false)
            .transition(.opacity)
        }
    }

    private func startCountdown() {
        guard countdown == nil, !state.isTiming else { return }
        Task { @MainActor in
            for n in [3, 2, 1] {
                withAnimation(.easeOut(duration: 0.15)) { countdown = n }
                Haptics.countTick()
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
            withAnimation(.easeOut(duration: 0.15)) { countdown = 0 }  // GO
            Haptics.drop()
            state.startStopwatch()
            try? await Task.sleep(nanoseconds: 600_000_000)
            withAnimation(.easeOut(duration: 0.25)) { countdown = nil }
        }
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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
