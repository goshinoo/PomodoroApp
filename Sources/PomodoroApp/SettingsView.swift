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
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        section(title: vm.s_sectionTimer) {
                            durationRow(label: vm.s_workDuration,  icon: "🍅",
                                        value: $vm.workMins,  range: 1...90)
                            rowDivider
                            durationRow(label: vm.s_shortDuration, icon: "☕",
                                        value: $vm.shortMins, range: 1...30)
                            rowDivider
                            durationRow(label: vm.s_longDuration,  icon: "🌿",
                                        value: $vm.longMins,  range: 1...60)
                        }
                        section(title: vm.s_sectionPrefs) {
                            languageRow
                            rowDivider
                            toggleRow(icon: "⏭", label: vm.s_autoStart,    binding: $vm.autoStart)
                            rowDivider
                            toggleRow(icon: "✅", label: vm.s_clearTask,    binding: $vm.clearTaskOnComplete)
                            rowDivider
                            toggleRow(icon: "🔔", label: vm.s_sound,        binding: $vm.soundEnabled)
                            rowDivider
                            dndRow
                        }
                    }
                    .padding(16)
                }
            }
        }
        .preferredColorScheme(.dark)
        .frame(width: 380, height: 500)
    }

    // MARK: - Header

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
        .padding(.vertical, 12)
    }

    // MARK: - Section wrapper

    private func section<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white.opacity(0.3))
                .padding(.horizontal, 4)
                .padding(.bottom, 6)
            VStack(spacing: 0) {
                content()
            }
            .background(Color.appCard.cornerRadius(12))
        }
    }

    private var rowDivider: some View {
        Divider()
            .background(Color.white.opacity(0.06))
            .padding(.leading, 40)
    }

    // MARK: - Row types

    private func durationRow(label: String, icon: String,
                              value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        HStack {
            Text(icon).font(.system(size: 14)).frame(width: 24)
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.85))
            Spacer()
            HStack(spacing: 0) {
                stepButton(icon: "minus") {
                    if value.wrappedValue > range.lowerBound { value.wrappedValue -= 1 }
                }
                Text("\(value.wrappedValue) \(vm.s_minutes)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 58)
                stepButton(icon: "plus") {
                    if value.wrappedValue < range.upperBound { value.wrappedValue += 1 }
                }
            }
            .background(Color.white.opacity(0.07).cornerRadius(8))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
    }

    private func toggleRow(icon: String, label: String, binding: Binding<Bool>) -> some View {
        HStack {
            Text(icon).font(.system(size: 14)).frame(width: 24)
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.85))
            Spacer()
            Toggle("", isOn: binding)
                .toggleStyle(.switch)
                .labelsHidden()
                .scaleEffect(0.85)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
    }

    private var languageRow: some View {
        HStack {
            Text("🌐").font(.system(size: 14)).frame(width: 24)
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
            .frame(width: 120)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
    }

    private var dndRow: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("🌙").font(.system(size: 14)).frame(width: 24)
                Text(vm.s_dndIntegration)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.85))
                Spacer()
                Toggle("", isOn: $vm.dndIntegrationEnabled)
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .scaleEffect(0.85)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)

            if vm.dndIntegrationEnabled {
                HStack(spacing: 10) {
                    Button(vm.s_dndInstall) { vm.installDNDShortcuts() }
                        .buttonStyle(.plain)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.workAccent)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(Color.workAccent.opacity(0.12).cornerRadius(6))
                        .overlay(RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.workAccent.opacity(0.3), lineWidth: 0.5))
                    Text(vm.s_dndInstallHint)
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.3))
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 10)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: vm.dndIntegrationEnabled)
    }

    private func stepButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white.opacity(0.55))
                .frame(width: 28, height: 28)
        }
        .buttonStyle(.plain)
    }
}
