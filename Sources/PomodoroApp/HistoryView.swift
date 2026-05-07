import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct HistoryView: View {
    let records: [DayRecord]
    @EnvironmentObject private var vm: TimerViewModel
    @Environment(\.dismiss) private var dismiss

    var totalPomodoros: Int { records.reduce(0) { $0 + $1.pomodoros } }
    var totalMinutes: Int   { records.reduce(0) { $0 + $1.focusMinutes } }

    var body: some View {
        ZStack {
            Color.appBg.ignoresSafeArea()
            VStack(spacing: 0) {
                header
                if records.isEmpty {
                    emptyState
                } else {
                    weeklyChart
                    Divider().background(Color.white.opacity(0.07))
                    summary
                    Divider().background(Color.white.opacity(0.07))
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 8) {
                            ForEach(records) { DayCard(record: $0) }
                        }
                        .padding(16)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .frame(width: 400, height: 540)
    }

    private var header: some View {
        HStack {
            Text(vm.s_historyTitle)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
            Spacer()
            if !records.isEmpty {
                Button {
                    exportCSV()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.4))
                }
                .buttonStyle(.plain)
                .padding(.trailing, 6)
            }
            Button(vm.s_done) { dismiss() }
                .buttonStyle(.plain)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.workAccent)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }

    private var weeklyChart: some View {
        let data = vm.last7Days()
        let maxCount = max(data.map(\.count).max() ?? 1, 1)
        return HStack(alignment: .bottom, spacing: 8) {
            ForEach(data, id: \.label) { day in
                VStack(spacing: 4) {
                    if day.count > 0 {
                        Text("\(day.count)")
                            .font(.system(size: 10))
                            .foregroundColor(.workAccent)
                    }
                    RoundedRectangle(cornerRadius: 3)
                        .fill(day.count > 0 ? Color.workAccent.opacity(0.7) : Color.white.opacity(0.07))
                        .frame(width: 28, height: max(4, CGFloat(day.count) / CGFloat(maxCount) * 60))
                    Text(day.label)
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.3))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.appCard)
    }

    private func exportCSV() {
        var lines = ["Date,Task,Pomodoros,FocusMinutes"]
        for record in records {
            for item in record.items {
                let safeTask = item.task.replacingOccurrences(of: "\"", with: "\"\"")
                lines.append("\(record.date),\"\(safeTask)\",\(item.count),\(item.count * vm.workMins)")
            }
        }
        let csv = lines.joined(separator: "\n")
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "pomodoro_export.csv"
        panel.allowedContentTypes = [.commaSeparatedText]
        if panel.runModal() == .OK, let url = panel.url {
            try? csv.write(to: url, atomically: true, encoding: .utf8)
        }
    }

    private var summary: some View {
        HStack(spacing: 0) {
            summaryCell(value: "\(records.count)", label: vm.s_recordDays)
            Rectangle().fill(Color.white.opacity(0.08)).frame(width: 1, height: 28)
            summaryCell(value: "\(totalPomodoros)", label: vm.s_totalPomo)
            Rectangle().fill(Color.white.opacity(0.08)).frame(width: 1, height: 28)
            summaryCell(value: "\(totalMinutes)", label: vm.s_totalMins)
        }
        .padding(.vertical, 12)
        .background(Color.appCard)
    }

    private func summaryCell(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.workAccent)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Text("🍅").font(.system(size: 52))
            Text(vm.s_noHistoryTitle)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.35))
            Text(vm.s_noHistoryBody)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.2))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Day Card

struct DayCard: View {
    let record: DayRecord
    @EnvironmentObject private var vm: TimerViewModel
    @State private var expanded = true

    var body: some View {
        VStack(spacing: 0) {
            dayHeader
            if expanded { taskList }
        }
        .background(Color.appCard.cornerRadius(12))
        .animation(.spring(response: 0.28, dampingFraction: 0.8), value: expanded)
    }

    private var dayHeader: some View {
        Button { expanded.toggle() } label: {
            HStack(spacing: 8) {
                Text(record.displayDate(language: vm.language))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Text("🍅").font(.system(size: 11))
                        Text("\(record.pomodoros)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.workAccent)
                    }
                    HStack(spacing: 3) {
                        Image(systemName: "clock")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.35))
                        Text("\(record.focusMinutes)\(vm.s_minutes)")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.45))
                    }
                }
                Image(systemName: expanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.25))
                    .padding(.leading, 2)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var taskList: some View {
        if !record.items.isEmpty {
            Divider().background(Color.white.opacity(0.06))
            VStack(spacing: 0) {
                ForEach(Array(record.items.enumerated()), id: \.element.id) { idx, item in
                    HStack {
                        Text(item.task.isEmpty ? vm.s_defaultTask : item.task)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.75))
                        Spacer()
                        Text("🍅×\(item.count)")
                            .font(.system(size: 11))
                            .foregroundColor(.workAccent)
                        Text(item.time)
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.3))
                            .padding(.leading, 6)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    if idx < record.items.count - 1 {
                        Divider().background(Color.white.opacity(0.04)).padding(.leading, 14)
                    }
                }
            }
        }
    }
}
