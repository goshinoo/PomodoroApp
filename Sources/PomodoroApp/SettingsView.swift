import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var vm: TimerViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.appBg.ignoresSafeArea()
            VStack(spacing: 0) {
                header
                Divider().background(Color.white.opacity(0.07))
                VStack(spacing: 6) {
                    durationRow(label: "专注时长", icon: "🍅",
                                value: $vm.workMins, range: 1...90)
                    durationRow(label: "短休息",   icon: "☕",
                                value: $vm.shortMins, range: 1...30)
                    durationRow(label: "长休息",   icon: "🌿",
                                value: $vm.longMins, range: 1...60)
                }
                .padding(16)
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
        .frame(width: 400, height: 260)
    }

    private var header: some View {
        HStack {
            Text("时长设置")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
            Spacer()
            Button("完成") { dismiss() }
                .buttonStyle(.plain)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.workAccent)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }

    private func durationRow(label: String, icon: String,
                              value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        HStack {
            Text(icon).font(.system(size: 15))
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.85))
            Spacer()
            HStack(spacing: 0) {
                stepButton(icon: "minus") {
                    if value.wrappedValue > range.lowerBound { value.wrappedValue -= 1 }
                }
                Text("\(value.wrappedValue) 分钟")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 60)
                stepButton(icon: "plus") {
                    if value.wrappedValue < range.upperBound { value.wrappedValue += 1 }
                }
            }
            .background(Color.appCard.cornerRadius(9))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.appCard.opacity(0.5).cornerRadius(10))
    }

    private func stepButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))
                .frame(width: 30, height: 30)
        }
        .buttonStyle(.plain)
    }
}
