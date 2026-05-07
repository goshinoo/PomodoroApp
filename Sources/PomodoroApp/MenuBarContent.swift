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
            modeRow
            Divider().opacity(0.15)
            timerRow
            Divider().opacity(0.15)
            controlRow
        }
        .frame(width: 220)
        .background(Color.appBg)
    }

    private var modeRow: some View {
        HStack {
            Text(modeIcon)
                .font(.system(size: 14))
            Text(vm.mode.rawValue)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
            Spacer()
            if vm.isRunning {
                Circle()
                    .fill(accent)
                    .frame(width: 7, height: 7)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var timerRow: some View {
        Text(vm.timeString)
            .font(.system(size: 42, weight: .bold, design: .monospaced))
            .foregroundColor(.white)
            .monospacedDigit()
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
    }

    private var controlRow: some View {
        HStack(spacing: 10) {
            menuButton(icon: "arrow.counterclockwise") { vm.reset() }

            Button { vm.toggle() } label: {
                Text(vm.isRunning ? "暂停" : "开始")
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

    private var modeIcon: String {
        switch vm.mode {
        case .work:        return "🍅"
        case .shortBreak:  return "☕"
        case .longBreak:   return "🌿"
        }
    }
}
