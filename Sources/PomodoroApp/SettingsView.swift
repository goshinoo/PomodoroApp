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
                VStack(spacing: 10) {
                    durationRow(label: vm.s_workDuration,  icon: "🍅",
                                value: $vm.workMins,  range: 1...90)
                    durationRow(label: vm.s_shortDuration, icon: "☕",
                                value: $vm.shortMins, range: 1...30)
                    durationRow(label: vm.s_longDuration,  icon: "🌿",
                                value: $vm.longMins,  range: 1...60)
                    languageRow
                    autoStartRow
                    clearTaskRow
                    soundRow
                }
                .padding(16)
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
        .frame(width: 400, height: 460)
    }

    private var header: some View {
        HStack {
            Text(vm.s_settingsTitle)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
            Spacer()
            Button(vm.s_done) { dismiss() }
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
                Text("\(value.wrappedValue) \(vm.s_minutes)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 68)
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

    private var languageRow: some View {
        HStack {
            Text("🌐").font(.system(size: 15))
            Text(vm.s_language)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.85))
            Spacer()
            Picker("", selection: $vm.language) {
                ForEach(AppLanguage.allCases, id: \.self) { lang in
                    Text(lang.displayName).tag(lang)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 130)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.appCard.opacity(0.5).cornerRadius(10))
    }

    private var autoStartRow: some View {
        HStack {
            Text("⏭").font(.system(size: 15))
            Text(vm.s_autoStart)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.85))
            Spacer()
            Toggle("", isOn: $vm.autoStart)
                .toggleStyle(.switch)
                .labelsHidden()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.appCard.opacity(0.5).cornerRadius(10))
    }

    private var clearTaskRow: some View {
        HStack {
            Text("✅").font(.system(size: 15))
            Text(vm.s_clearTask)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.85))
            Spacer()
            Toggle("", isOn: $vm.clearTaskOnComplete)
                .toggleStyle(.switch)
                .labelsHidden()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.appCard.opacity(0.5).cornerRadius(10))
    }

    private var soundRow: some View {
        HStack {
            Text("🔔").font(.system(size: 15))
            Text(vm.s_sound)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.85))
            Spacer()
            Toggle("", isOn: $vm.soundEnabled)
                .toggleStyle(.switch)
                .labelsHidden()
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
