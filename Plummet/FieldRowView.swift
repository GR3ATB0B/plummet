import SwiftUI

struct FieldRowView: View {
    let variable: Variable
    @ObservedObject var state: SolverState
    @State private var expanded = false

    static func label(_ v: Variable) -> String {
        switch v {
        case .s: return "s  height"
        case .v0: return "v₀ launch"
        case .v: return "v  final"
        case .a: return "a  accel"
        case .t: return "t  time"
        }
    }

    static func unit(_ v: Variable) -> String {
        switch v {
        case .s: return "m"
        case .v0, .v: return "m/s"
        case .a: return "m/s²"
        case .t: return "s"
        }
    }

    private var origin: FieldOrigin { state.origin[variable] ?? .empty }

    private var valueColor: Color {
        switch origin {
        case .solved: return GridMetrics.inkGreen
        case .conflicted: return Color(red: 0.64, green: 0.18, blue: 0.11)
        default: return GridMetrics.ink
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            row
            if expanded, let sv = state.solved[variable] {
                workedSteps(sv)
            }
        }
    }

    private var row: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(Self.label(variable))
                .font(GridMetrics.mono)
                .foregroundStyle(GridMetrics.inkGreen)
            Spacer()
            if origin == .solved {
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) { expanded.toggle() }
                } label: {
                    Text(expanded ? "▾" : "▸")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(GridMetrics.inkGreenSoft)
                }
                .buttonStyle(.plain)
            }
            TextField("—", text: Binding(
                get: { state.fields[variable] ?? "" },
                set: { state.setField(variable, to: $0) }
            ))
            .keyboardType(.numbersAndPunctuation)
            .multilineTextAlignment(.trailing)
            .font(GridMetrics.mono)
            .foregroundStyle(valueColor)
            .frame(width: GridMetrics.square * 4)
            .transition(.move(edge: .top).combined(with: .opacity))
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: state.solved[variable]?.value)
            Text(Self.unit(variable))
                .font(.system(.footnote, design: .monospaced))
                .foregroundStyle(GridMetrics.pencil)
                .frame(width: GridMetrics.square * 2, alignment: .leading)
        }
        .frame(height: GridMetrics.square * 2)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(GridMetrics.pencil.opacity(origin == .conflicted ? 0.9 : 0.5))
                .frame(height: 1)
        }
    }

    private func workedSteps(_ sv: SolvedValue) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            stepLine(sv.equation)
            stepLine(sv.substitution)
            stepLine("\(Formatting.symbol(variable)) = \(Formatting.number(sv.value)) \(Self.unit(variable))")
        }
        .padding(.leading, GridMetrics.square)
    }

    private func stepLine(_ text: String) -> some View {
        Text(text)
            .font(.system(.footnote, design: .monospaced))
            .foregroundStyle(GridMetrics.inkGreenSoft)
            .frame(height: GridMetrics.square, alignment: .bottom)
            .overlay(alignment: .bottom) {
                Rectangle().fill(GridMetrics.line).frame(height: 1)
            }
    }
}
