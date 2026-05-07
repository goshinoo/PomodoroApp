import Foundation
import AppKit

struct HistoryItem: Codable, Identifiable {
    var id: UUID = UUID()
    var task: String
    var count: Int
    var time: String
    var date: String
}

struct DayRecord: Identifiable {
    var id: String { date }
    let date: String
    let pomodoros: Int
    let focusMinutes: Int
    let items: [HistoryItem]

    var displayDate: String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        guard let d = f.date(from: date) else { return date }
        if Calendar.current.isDateInToday(d)      { return "今天" }
        if Calendar.current.isDateInYesterday(d)  { return "昨天" }
        let df = DateFormatter()
        df.locale = Locale(identifier: "zh_CN")
        df.dateFormat = "M月d日"
        return df.string(from: d)
    }
}

class TimerViewModel: ObservableObject {
    enum Mode: String, CaseIterable {
        case work       = "专注"
        case shortBreak = "短休息"
        case longBreak  = "长休息"
    }

    // MARK: - Custom durations (minutes)
    @Published var workMins: Int  = 25 { didSet { saveDurations(); applyIfIdle(.work) } }
    @Published var shortMins: Int =  5 { didSet { saveDurations(); applyIfIdle(.shortBreak) } }
    @Published var longMins: Int  = 15 { didSet { saveDurations(); applyIfIdle(.longBreak) } }

    @Published var mode: Mode = .work
    @Published var remaining: Int = 25 * 60
    @Published var isRunning: Bool = false
    @Published var taskText: String = ""

    @Published var todayPomodoros: Int = 0
    @Published var focusMinutes: Int = 0
    @Published var streak: Int = 0
    @Published var history: [HistoryItem] = []

    private var total: Int = 25 * 60
    private var timer: Timer?
    private var sessionCount: Int = 0  // resets each app launch; drives short/long break alternation

    func durationFor(_ m: Mode) -> Int {
        switch m {
        case .work:        return workMins  * 60
        case .shortBreak:  return shortMins * 60
        case .longBreak:   return longMins  * 60
        }
    }

    private func applyIfIdle(_ m: Mode) {
        guard !isRunning, mode == m else { return }
        let d = durationFor(m)
        remaining = d
        total = d
    }

    var progress: Double {
        guard total > 0 else { return 1 }
        return Double(remaining) / Double(total)
    }

    var timeString: String {
        String(format: "%02d:%02d", remaining / 60, remaining % 60)
    }

    var menuBarLabel: String {
        let icon: String
        switch mode {
        case .work:        icon = "🍅"
        case .shortBreak:  icon = "☕"
        case .longBreak:   icon = "🌿"
        }
        return "\(icon) \(timeString)"
    }

    var sessionLabel: String {
        switch mode {
        case .work:        return "第 \(todayPomodoros + 1) 个番茄"
        case .shortBreak:  return "短暂休息中"
        case .longBreak:   return "长时休息中"
        }
    }

    init() {
        loadDurations()
        loadStats()
        remaining = workMins * 60
        total     = workMins * 60
    }

    // MARK: - Public

    func setMode(_ m: Mode) {
        stopTimer()
        mode = m
        let d = durationFor(m)
        remaining = d
        total = d
    }

    func toggle() { isRunning ? pauseTimer() : startTimer() }

    func reset() {
        stopTimer()
        remaining = total
    }

    func skip() {
        stopTimer()
        handleComplete()
    }

    func clearHistory() {
        history = []
        saveStats()
    }

    // MARK: - Timer

    private func startTimer() {
        isRunning = true
        let t = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            DispatchQueue.main.async { self?.tick() }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func pauseTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    private func stopTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        if remaining > 0 { remaining -= 1 } else { handleComplete() }
    }

    private func handleComplete() {
        stopTimer()
        playSound()

        if mode == .work {
            sessionCount += 1
            todayPomodoros += 1
            focusMinutes += workMins
            recordHistory()
            saveStats()
            bumpStreak()
            sendNotification(title: "番茄钟完成 🍅", body: "休息一下吧！")
            setMode(sessionCount % 4 == 0 ? .longBreak : .shortBreak)
        } else {
            sendNotification(title: "休息结束", body: "准备好开始下一个番茄了吗？")
            setMode(.work)
        }
    }

    private func recordHistory() {
        let task = taskText.trimmingCharacters(in: .whitespaces)
        let timeStr = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .short)
        let today = todayKey()

        if let last = history.indices.last,
           history[last].task == task,
           history[last].date == today {
            history[last].count += 1
            history[last].time = timeStr
        } else {
            history.append(HistoryItem(task: task, count: 1, time: timeStr, date: today))
        }
    }

    private func playSound() {
        let name = (mode == .work) ? "Glass" : "Blow"
        NSSound(named: NSSound.Name(name))?.play()
    }

    private func sendNotification(title: String, body: String) {
        let safeTitle = title.replacingOccurrences(of: "\"", with: "\\\"")
        let safeBody  = body.replacingOccurrences(of:  "\"", with: "\\\"")
        let script = "display notification \"\(safeBody)\" with title \"\(safeTitle)\""
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        task.arguments = ["-e", script]
        try? task.run()
    }

    // MARK: - Persistence

    private func todayKey() -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }

    private func loadStats() {
        let k = todayKey()
        todayPomodoros = UserDefaults.standard.integer(forKey: "pomo_count_\(k)")
        focusMinutes   = UserDefaults.standard.integer(forKey: "pomo_mins_\(k)")
        if let d = UserDefaults.standard.data(forKey: "pomo_hist_\(k)"),
           let h = try? JSONDecoder().decode([HistoryItem].self, from: d) {
            history = h
        }
        streak = computeStreak()
    }

    private func saveStats() {
        let k = todayKey()
        UserDefaults.standard.set(todayPomodoros, forKey: "pomo_count_\(k)")
        UserDefaults.standard.set(focusMinutes,   forKey: "pomo_mins_\(k)")
        if let d = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(d, forKey: "pomo_hist_\(k)")
        }
    }

    private func loadDurations() {
        let d = UserDefaults.standard
        if d.object(forKey: "pomo_dur_work")  != nil { workMins  = d.integer(forKey: "pomo_dur_work") }
        if d.object(forKey: "pomo_dur_short") != nil { shortMins = d.integer(forKey: "pomo_dur_short") }
        if d.object(forKey: "pomo_dur_long")  != nil { longMins  = d.integer(forKey: "pomo_dur_long") }
    }

    private func saveDurations() {
        let d = UserDefaults.standard
        d.set(workMins,  forKey: "pomo_dur_work")
        d.set(shortMins, forKey: "pomo_dur_short")
        d.set(longMins,  forKey: "pomo_dur_long")
    }

    private func computeStreak() -> Int {
        guard let dict = UserDefaults.standard.dictionary(forKey: "pomo_streak"),
              let lastDay = dict["lastDay"] as? String,
              let s = dict["streak"] as? Int else { return 0 }
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        guard let last = f.date(from: lastDay) else { return 0 }
        let days = Calendar.current.dateComponents([.day], from: last, to: Date()).day ?? 99
        return (days <= 1) ? s : 0
    }

    private func bumpStreak() {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        let today = f.string(from: Date())
        if let dict = UserDefaults.standard.dictionary(forKey: "pomo_streak"),
           let lastDay = dict["lastDay"] as? String, lastDay == today { return }
        let newS = computeStreak() + 1
        UserDefaults.standard.set(["lastDay": today, "streak": newS], forKey: "pomo_streak")
        streak = newS
    }

    func loadAllHistory() -> [DayRecord] {
        let defaults = UserDefaults.standard
        let dates = defaults.dictionaryRepresentation().keys
            .filter { $0.hasPrefix("pomo_count_") }
            .map    { String($0.dropFirst("pomo_count_".count)) }
            .sorted(by: >)

        return dates.compactMap { date in
            let count = defaults.integer(forKey: "pomo_count_\(date)")
            guard count > 0 else { return nil }
            let mins = defaults.integer(forKey: "pomo_mins_\(date)")
            var items: [HistoryItem] = []
            if let d = defaults.data(forKey: "pomo_hist_\(date)"),
               let h = try? JSONDecoder().decode([HistoryItem].self, from: d) {
                items = h
            }
            return DayRecord(date: date, pomodoros: count, focusMinutes: mins, items: items)
        }
    }
}
