import SwiftUI

struct MenuBarContent: View {
    @EnvironmentObject private var vm: TimerViewModel

    private var accent: Color {
        switch vm.mode {
        case .work:        return .workAccent
        case .shortBreak:  return .shortAccent
        case .longBreak:   return .longAccent
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            modeTabsRow
            Divider().opacity(0.15)
            timerRow
            Divider().opacity(0.15)
            controlRow
        }
        .frame(width: 220)
        .background(Color.appBg)
    }

    private var modeTabsRow: some View {
        HStack(spacing: 4) {
            ForEach(TimerViewModel.Mode.allCases, id: \.self) { m in
                Button { vm.setMode(m) } label: {
                    HStack(spacing: 4) {
                        Text(iconFor(m)).font(.system(size: 11))
                        Text(vm.modeName(m))
                            .font(.system(size: 11, weight: vm.mode == m ? .semibold : .regular))
                            .foregroundColor(vm.mode == m ? .white : .white.opacity(0.45))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(vm.mode == m ? accent.opacity(0.85) : Color.clear)
                            .animation(.spring(response: 0.2), value: vm.mode)
                    )
                }
                .buttonStyle(.plain)
                .disabled(vm.isRunning && vm.mode != m)
                .opacity(vm.isRunning && vm.mode != m ? 0.3 : 1.0)
                .animation(.easeOut(duration: 0.2), value: vm.isRunning)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }

    private var timerRow: some View {
        HStack {
            Text(vm.timeString)
                .font(.system(size: 38, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .monospacedDigit()
                .frame(maxWidth: .infinity)

            if vm.isRunning {
                Circle()
                    .fill(accent)
                    .frame(width: 7, height: 7)
                    .padding(.trailing, 14)
            }
        }
        .padding(.vertical, 12)
    }

    private var controlRow: some View {
        HStack(spacing: 10) {
            menuButton(icon: "arrow.counterclockwise") { vm.reset() }

            Button { vm.toggle() } label: {
                Text(vm.isRunning ? vm.s_pause : vm.s_start)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(accent.cornerRadius(8))
            }
            .buttonStyle(.plain)

            menuButton(icon: "forward.end.fill") { vm.skip() }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private func menuButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.55))
                .frame(width: 32, height: 32)
                .background(Color.appCard)
                .clipShape(RoundedRectangle(cornerRadius: 7))
        }
        .buttonStyle(.plain)
    }

    private func iconFor(_ m: TimerViewModel.Mode) -> String {
        switch m {
        case .work:        return "🍅"
        case .shortBreak:  return "☕"
        case .longBreak:   return "🌿"
        }
    }
}
