import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var vm: TimerViewModel
    @State private var showHistory = false
    @State private var historyRecords: [DayRecord] = []
    @State private var showSettings = false

    private var accent: Color {
        switch vm.mode {
        case .work:        return .workAccent
        case .shortBreak:  return .shortAccent
        case .longBreak:   return .longAccent
        }
    }

    var body: some View {
        ZStack {
            Color.appBg.ignoresSafeArea()

            VStack(spacing: 0) {
                dragArea
                modeTabs.padding(.bottom, 12)
                taskInput.padding(.horizontal, 20).padding(.bottom, 10)
                timerRing.padding(.bottom, 14)
                controlButtons.padding(.bottom, 18)
                statsBar.padding(.horizontal, 20).padding(.bottom, 14)
                historySection.padding(.horizontal, 20)
                Spacer(minLength: 0)
            }
        }
        .preferredColorScheme(.dark)
        .ignoresSafeArea(.all, edges: .top)
        .sheet(isPresented: $showHistory) {
            HistoryView(records: historyRecords)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView().environmentObject(vm)
        }
    }

    // MARK: - Drag area

    private var dragArea: some View {
        ZStack {
            Text("🍅  Pomodoro")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.35))
            HStack {
                Spacer()
                HStack(spacing: 2) {
                    Button { showSettings = true } label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.35))
                            .padding(6)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    Button {
                        historyRecords = vm.loadAllHistory()
                        showHistory = true
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.35))
                            .padding(6)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.trailing, 4)
            }
        }
        .frame(height: 28)
    }

    // MARK: - Mode tabs

    private var modeTabs: some View {
        HStack(spacing: 6) {
            ForEach(TimerViewModel.Mode.allCases, id: \.self) { m in
                Button { vm.setMode(m) } label: {
                    Text(m.rawValue)
                        .font(.system(size: 13, weight: vm.mode == m ? .semibold : .regular))
                        .foregroundColor(vm.mode == m ? .white : .white.opacity(0.45))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 7)
                        .background(
                            RoundedRectangle(cornerRadius: 9)
                                .fill(vm.mode == m ? accent : Color.clear)
                                .animation(.spring(response: 0.25), value: vm.mode)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color.appCard.cornerRadius(13))
    }

    // MARK: - Task input

    private var taskInput: some View {
        TextField("正在做什么？（可选）", text: $vm.taskText)
            .textFieldStyle(.plain)
            .font(.system(size: 13))
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.appCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                vm.taskText.isEmpty ? Color.white.opacity(0.08) : accent.opacity(0.6),
                                lineWidth: 1
                            )
                    )
            )
    }

    // MARK: - Timer ring

    private var timerRing: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.06), lineWidth: 10)

            Circle()
                .trim(from: 0, to: vm.progress)
                .stroke(accent, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.9), value: vm.progress)

            VStack(spacing: 4) {
                Text(vm.timeString)
                    .font(.system(size: 46, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .monospacedDigit()

                Text(vm.sessionLabel)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.45))
            }
        }
        .frame(width: 190, height: 190)
    }

    // MARK: - Controls

    private var controlButtons: some View {
        HStack(spacing: 16) {
            circleButton(icon: "arrow.counterclockwise", help: "重置") { vm.reset() }

            Button { vm.toggle() } label: {
                Text(vm.isRunning ? "暂停" : "开始")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 120, height: 44)
                    .background(accent.cornerRadius(22))
            }
            .buttonStyle(.plain)
            .animation(.spring(response: 0.25), value: vm.isRunning)

            circleButton(icon: "forward.end.fill", help: "跳过") { vm.skip() }
        }
    }

    private func circleButton(icon: String, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 17))
                .foregroundColor(.white.opacity(0.5))
                .frame(width: 44, height: 44)
                .background(Color.appCard)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .help(help)
    }

    // MARK: - Stats

    private var statsBar: some View {
        HStack(spacing: 0) {
            statCell(value: "\(vm.todayPomodoros)", label: "今日番茄")
            Rectangle().fill(Color.white.opacity(0.08)).frame(width: 1, height: 30)
            statCell(value: "\(vm.focusMinutes)", label: "专注分钟")
            Rectangle().fill(Color.white.opacity(0.08)).frame(width: 1, height: 30)
            statCell(value: "\(vm.streak)", label: "连续天数")
        }
        .padding(.vertical, 12)
        .background(Color.appCard.cornerRadius(14))
    }

    private func statCell(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(accent)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - History

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("今日任务")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.4))
                Spacer()
                if !vm.history.isEmpty {
                    Button("清空") { vm.clearHistory() }
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.3))
                        .buttonStyle(.plain)
                }
            }

            if vm.history.isEmpty {
                Text("暂无记录")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.2))
                    .frame(maxWidth: .infinity)
                    .padding(.top, 16)
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 4) {
                        ForEach(vm.history.reversed()) { item in
                            HStack {
                                Text(item.task.isEmpty ? "专注" : item.task)
                                    .font(.system(size: 13))
                                    .foregroundColor(.white.opacity(0.85))
                                Spacer()
                                Text("🍅×\(item.count)  \(item.time)")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.4))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.appCard.cornerRadius(8))
                        }
                    }
                }
                .frame(maxHeight: 110)
            }
        }
    }
}

// MARK: - Colors

extension Color {
    static let appBg       = Color(red: 0.102, green: 0.102, blue: 0.180)
    static let appCard     = Color(red: 0.086, green: 0.129, blue: 0.243)
    static let workAccent  = Color(red: 0.910, green: 0.365, blue: 0.365)
    static let shortAccent = Color(red: 0.298, green: 0.686, blue: 0.541)
    static let longAccent  = Color(red: 0.357, green: 0.553, blue: 0.933)
}
