import SwiftUI

struct StopwatchBar: View {
    @ObservedObject var state: SolverState
    @State private var display: TimeInterval = 0
    private let tick = Timer.publish(every: 0.03, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: GridMetrics.square) {
            Text(String(format: "%.2f s", state.isTiming ? display : state.elapsed))
                .font(.system(size: 20, weight: .regular, design: .monospaced))
                .foregroundStyle(GridMetrics.ink)
            Spacer()
            Button {
                if state.isTiming {
                    state.stopStopwatch()
                    Haptics.tap()
                } else {
                    state.startStopwatch()
                    Haptics.tap()
                }
            } label: {
                Text(state.isTiming ? "◼ STOP" : "▷ START")
                    .font(.system(size: 16, design: .monospaced))
                    .foregroundStyle(GridMetrics.paper)
                    .padding(.horizontal, GridMetrics.square)
                    .frame(height: GridMetrics.square * 2)
                    .background(GridMetrics.inkGreen)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
        .frame(height: GridMetrics.square * 3)
        .onReceive(tick) { _ in
            if state.isTiming { display += 0.03 }
            else { display = 0 }
        }
    }
}

enum Haptics {
    static func tap() {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        #endif
    }

    /// A firm tick for each countdown number (3, 2, 1).
    static func countTick() {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
    }

    /// A heavy thump at "GO" — the drop.
    static func drop() {
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        #endif
    }
}
