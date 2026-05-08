import AppKit
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var vm: TimerViewModel
    @State private var showHistory = false
    @State private var showSettings = false
    @State private var showSuggestions = false
    @State private var showClearConfirm = false
    @FocusState private var taskFocused: Bool
    @State private var ringPulse = false
    @State private var keyMonitor: Any?
    // Reference-type bridge so the NSEvent closure can read live focus state
    @State private var focusBridge = FocusBridge()

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
            HistoryView(records: vm.loadAllHistory()).environmentObject(vm)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView().environmentObject(vm)
        }
        .onAppear {
            // Prevent TextField from auto-grabbing focus when the window opens
            DispatchQueue.main.async {
                NSApp.keyWindow?.makeFirstResponder(nil)
            }
            keyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .leftMouseDown]) { [bridge = focusBridge] event in
                // Click anywhere: dismiss text field focus (return event so buttons still fire)
                if event.type == .leftMouseDown, bridge.taskEditing {
                    DispatchQueue.main.async { NSApp.keyWindow?.makeFirstResponder(nil) }
                    return event
                }
                guard event.type == .keyDown else { return event }
                // Escape: resign text field focus
                if event.keyCode == 53, bridge.taskEditing {
                    DispatchQueue.main.async { NSApp.keyWindow?.makeFirstResponder(nil) }
                    return nil
                }
                // Space: toggle timer only when text field is not editing
                guard event.keyCode == 49,
                      event.modifierFlags.intersection([.command, .option, .control, .shift]).isEmpty,
                      !bridge.taskEditing
                else { return event }
                DispatchQueue.main.async { vm.toggle() }
                return nil
            }
        }
        .onDisappear {
            if let m = keyMonitor { NSEvent.removeMonitor(m); keyMonitor = nil }
        }
        .onChange(of: vm.isRunning) { running in
            if running {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    ringPulse = true
                }
            } else {
                withAnimation(.easeOut(duration: 0.4)) {
                    ringPulse = false
                }
            }
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
                    IconButton(icon: "slider.horizontal.3") { showSettings = true }
                    IconButton(icon: "clock.arrow.circlepath") {
                        showHistory = true
                    }
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
                    Text(vm.modeName(m))
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
                .disabled(vm.isRunning && vm.mode != m)
                .opacity(vm.isRunning && vm.mode != m ? 0.3 : 1.0)
                .animation(.easeOut(duration: 0.2), value: vm.isRunning)
            }
        }
        .padding(4)
        .background(Color.appCard.cornerRadius(13))
    }

    // MARK: - Task input

    private var taskInput: some View {
        ZStack(alignment: .topLeading) {
            TextField(vm.s_taskPlaceholder, text: $vm.taskText)
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
                .focused($taskFocused)
                .onChange(of: taskFocused) { focused in
                    focusBridge.taskEditing = focused
                    showSuggestions = focused && !vm.recentTasks.isEmpty
                }
                .onSubmit { showSuggestions = false }

            if showSuggestions && !vm.recentTasks.isEmpty {
                VStack(spacing: 0) {
                    ForEach(vm.recentTasks, id: \.self) { task in
                        Button {
                            vm.taskText = task
                            showSuggestions = false
                            taskFocused = false
                        } label: {
                            Text(task)
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.75))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .background(Color.appCard.cornerRadius(8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
                .offset(y: 38)
                .zIndex(10)
            }
        }
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
                .shadow(
                    color: vm.isRunning ? accent.opacity(ringPulse ? 0.55 : 0.12) : .clear,
                    radius: 10
                )

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
            CircleButton(icon: "arrow.counterclockwise", help: vm.s_reset) { vm.reset() }

            StartPauseButton(label: vm.isRunning ? vm.s_pause : vm.s_start, accent: accent) {
                vm.toggle()
            }

            CircleButton(icon: "forward.end.fill", help: vm.s_skip) { vm.skip() }
        }
    }

    // MARK: - Stats

    private var statsBar: some View {
        HStack(spacing: 0) {
            statCell(value: "\(vm.todayPomodoros)", label: vm.s_todayPomo)
            Rectangle().fill(Color.white.opacity(0.08)).frame(width: 1, height: 30)
            statCell(value: "\(vm.focusMinutes)", label: vm.s_focusMins)
            Rectangle().fill(Color.white.opacity(0.08)).frame(width: 1, height: 30)
            statCell(value: "\(vm.streak)", label: vm.s_streakDays)
        }
        .padding(.vertical, 12)
        .background(Color.appCard.cornerRadius(14))
    }

    private func statCell(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(accent)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.4), value: value)
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
                Text(vm.s_todayTasks)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.4))
                Spacer()
                if !vm.history.isEmpty {
                    Button(vm.s_clear) { showClearConfirm = true }
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.3))
                        .buttonStyle(.plain)
                        .confirmationDialog(vm.s_clearConfirm, isPresented: $showClearConfirm, titleVisibility: .visible) {
                            Button(vm.s_clear, role: .destructive) { vm.clearHistory() }
                        }
                }
            }

            if vm.history.isEmpty {
                Text(vm.s_noRecords)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.2))
                    .padding(.top, 4)
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 4) {
                        ForEach(vm.history.reversed()) { item in
                            HStack {
                                Text(item.task.isEmpty ? vm.s_defaultTask : item.task)
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

// MARK: - Focus bridge (reference type so NSEvent closure sees live state)

final class FocusBridge {
    var taskEditing = false
}

// MARK: - Button components

struct CircleButton: View {
    let icon: String
    let help: String
    let action: () -> Void
    @State private var hovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 17))
                .foregroundColor(.white.opacity(hovered ? 0.85 : 0.5))
                .frame(width: 44, height: 44)
                .background(Color.appCard.brightness(hovered ? 0.06 : 0))
                .clipShape(Circle())
                .scaleEffect(hovered ? 1.07 : 1.0)
        }
        .buttonStyle(.plain)
        .help(help)
        .onHover { hovered = $0 }
        .animation(.easeOut(duration: 0.14), value: hovered)
    }
}

struct StartPauseButton: View {
    let label: String
    let accent: Color
    let action: () -> Void
    @State private var hovered = false

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 120, height: 44)
                .background(accent.opacity(hovered ? 0.80 : 1.0).cornerRadius(22))
                .scaleEffect(hovered ? 1.04 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { hovered = $0 }
        .animation(.easeOut(duration: 0.14), value: hovered)
    }
}

struct IconButton: View {
    let icon: String
    let action: () -> Void
    @State private var hovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(hovered ? 0.75 : 0.35))
                .padding(6)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovered = $0 }
        .animation(.easeOut(duration: 0.12), value: hovered)
    }
}

