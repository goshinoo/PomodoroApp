import Foundation
import AppKit

struct HistoryItem: Codable, Identifiable {
    var id: UUID = UUID()
    var task: String
    var count: Int
    var time: String
    var date: String
}

enum AppLanguage: String, CaseIterable {
    case chinese = "zh"
    case english = "en"
    var displayName: String { self == .chinese ? "中文" : "English" }
}

struct DayRecord: Identifiable {
    var id: String { date }
    let date: String
    let pomodoros: Int
    let focusMinutes: Int
    let items: [HistoryItem]

    func displayDate(language: AppLanguage) -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        guard let d = f.date(from: date) else { return date }
        if language == .chinese {
            if Calendar.current.isDateInToday(d)     { return "今天" }
            if Calendar.current.isDateInYesterday(d) { return "昨天" }
            let df = DateFormatter(); df.locale = Locale(identifier: "zh_CN"); df.dateFormat = "M月d日"
            return df.string(from: d)
        } else {
            if Calendar.current.isDateInToday(d)     { return "Today" }
            if Calendar.current.isDateInYesterday(d) { return "Yesterday" }
            let df = DateFormatter(); df.locale = Locale(identifier: "en_US"); df.dateFormat = "MMM d"
            return df.string(from: d)
        }
    }
}

class TimerViewModel: ObservableObject {
    enum Mode: String, CaseIterable {
        case work       = "专注"
        case shortBreak = "短休息"
        case longBreak  = "长休息"
    }

    @Published var language: AppLanguage = .english {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: "app_language") }
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

    @Published var autoStart: Bool = false {
        didSet { UserDefaults.standard.set(autoStart, forKey: "pomo_auto_start") }
    }

    private var total: Int = 25 * 60
    private var timer: Timer?
    private var endDate: Date?
    private var sessionCount: Int = 0

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
        case .work:        return zh("第 \(todayPomodoros + 1) 个番茄", en: "Pomodoro #\(todayPomodoros + 1)")
        case .shortBreak:  return zh("短暂休息中", en: "Short break")
        case .longBreak:   return zh("长时休息中", en: "Long break")
        }
    }

    // MARK: - Localized strings

    private func zh(_ c: String, en e: String) -> String { language == .chinese ? c : e }

    func modeName(_ m: Mode) -> String {
        switch m {
        case .work:        return zh("专注",   en: "Focus")
        case .shortBreak:  return zh("短休息", en: "Short")
        case .longBreak:   return zh("长休息", en: "Long")
        }
    }

    var s_taskPlaceholder: String { zh("正在做什么？（可选）", en: "What are you working on? (optional)") }
    var s_start:           String { zh("开始",     en: "Start") }
    var s_pause:           String { zh("暂停",     en: "Pause") }
    var s_reset:           String { zh("重置",     en: "Reset") }
    var s_skip:            String { zh("跳过",     en: "Skip") }
    var s_todayPomo:       String { zh("今日番茄", en: "Today") }
    var s_focusMins:       String { zh("专注分钟", en: "Minutes") }
    var s_streakDays:      String { zh("连续天数", en: "Streak") }
    var s_todayTasks:      String { zh("今日任务", en: "Today's Tasks") }
    var s_noRecords:       String { zh("暂无记录", en: "No records yet") }
    var s_clear:           String { zh("清空",     en: "Clear") }
    var s_defaultTask:     String { zh("专注",     en: "Focus") }
    var s_historyTitle:    String { zh("历史记录", en: "History") }
    var s_done:            String { zh("完成",     en: "Done") }
    var s_recordDays:      String { zh("记录天数", en: "Days") }
    var s_totalPomo:       String { zh("累计番茄", en: "Pomodoros") }
    var s_totalMins:       String { zh("累计分钟", en: "Minutes") }
    var s_noHistoryTitle:  String { zh("还没有历史记录",           en: "No history yet") }
    var s_noHistoryBody:   String { zh("完成第一个番茄后这里会显示记录", en: "Complete your first pomodoro to see records here") }
    var s_settingsTitle:   String { zh("时长设置",  en: "Settings") }
    var s_workDuration:    String { zh("专注时长",  en: "Focus") }
    var s_shortDuration:   String { zh("短休息",    en: "Short Break") }
    var s_longDuration:    String { zh("长休息",    en: "Long Break") }
    var s_minutes:         String { zh("分钟",      en: "min") }
    var s_language:        String { zh("语言",      en: "Language") }
    var s_autoStart:       String { zh("自动开始",  en: "Auto-start") }

    init() {
        loadDurations()
        if let code = UserDefaults.standard.string(forKey: "app_language"),
           let lang = AppLanguage(rawValue: code) { language = lang }
        autoStart = UserDefaults.standard.bool(forKey: "pomo_auto_start")
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
        endDate = Date().addingTimeInterval(Double(remaining))
        let t = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            DispatchQueue.main.async { self?.tick() }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func pauseTimer() {
        isRunning = false
        endDate = nil
        timer?.invalidate()
        timer = nil
    }

    private func stopTimer() {
        isRunning = false
        endDate = nil
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        guard let end = endDate else { return }
        remaining = max(0, Int(ceil(end.timeIntervalSince(Date()))))
        if remaining == 0 { handleComplete() }
    }

    private func handleComplete() {
        stopTimer()
        playSound()

        if mode == .work {
            sessionCount += 1
            UserDefaults.standard.set(sessionCount, forKey: "pomo_session_count")
            todayPomodoros += 1
            focusMinutes += workMins
            recordHistory()
            saveStats()
            bumpStreak()
            sendNotification(title: zh("番茄钟完成 🍅", en: "Pomodoro Done 🍅"),
                             body:  zh("休息一下吧！",   en: "Time for a break!"))
            setMode(sessionCount % 4 == 0 ? .longBreak : .shortBreak)
        } else {
            sendNotification(title: zh("休息结束",       en: "Break Over"),
                             body:  zh("准备好开始下一个番茄了吗？", en: "Ready for the next pomodoro?"))
            setMode(.work)
        }
        if autoStart { startTimer() }
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

        let sessionDate = UserDefaults.standard.string(forKey: "pomo_session_date") ?? ""
        if sessionDate != k {
            sessionCount = 0
            UserDefaults.standard.set(k, forKey: "pomo_session_date")
            UserDefaults.standard.set(0, forKey: "pomo_session_count")
        } else {
            sessionCount = UserDefaults.standard.integer(forKey: "pomo_session_count")
        }
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

    func last7Days() -> [(label: String, count: Int, fullDate: String)] {
        let cal = Calendar.current
        let dayFmt = DateFormatter()
        dayFmt.locale = Locale(identifier: language == .chinese ? "zh_CN" : "en_US")
        dayFmt.dateFormat = "EEE"
        let fullFmt = DateFormatter()
        fullFmt.locale = Locale(identifier: language == .chinese ? "zh_CN" : "en_US")
        fullFmt.dateFormat = language == .chinese ? "M月d日" : "MMM d"
        let keyFmt = DateFormatter(); keyFmt.dateFormat = "yyyy-MM-dd"
        return (0..<7).reversed().map { offset in
            let date = cal.date(byAdding: .day, value: -offset, to: Date())!
            let key = keyFmt.string(from: date)
            let count = UserDefaults.standard.integer(forKey: "pomo_count_\(key)")
            let label = offset == 0
                ? zh("今", en: "T")
                : String(dayFmt.string(from: date).prefix(2))
            let fullDate = offset == 0
                ? zh("今天", en: "Today")
                : fullFmt.string(from: date)
            return (label: label, count: count, fullDate: fullDate)
        }
    }

    var recentTasks: [String] {
        let all = history.map { $0.task }.filter { !$0.isEmpty }
        return Array(NSOrderedSet(array: all).array as! [String]).prefix(5).map { $0 }
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
