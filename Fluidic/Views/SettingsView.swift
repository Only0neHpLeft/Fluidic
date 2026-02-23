import SwiftUI

struct SettingsView: View {
    @Bindable var viewModel: WaterViewModel
    @State private var showResetAlert = false

    private let cupSizes: [Double] = [100, 150, 200, 250, 330, 500]

    var body: some View {
        ZStack {
            FluidicTheme.backgroundGradient
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    Text("Settings")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(FluidicTheme.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)

                    // Daily goal card
                    settingsCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Daily Goal", systemImage: "target")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundStyle(FluidicTheme.textPrimary)

                            HStack {
                                Text(String(format: "%.1f L", (viewModel.settings?.dailyGoalML ?? 2500) / 1000))
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundStyle(FluidicTheme.accent)

                                Spacer()

                            Stepper("", value: Binding(
                                get: { viewModel.settings?.dailyGoalML ?? 2500 },
                                set: { 
                                    viewModel.settings?.dailyGoalML = $0
                                    viewModel.saveChanges()
                                }
                            ), in: 500...5000, step: 250)
                                .labelsHidden()
                            }

                            Slider(value: Binding(
                                get: { viewModel.settings?.dailyGoalML ?? 2500 },
                                set: { 
                                    viewModel.settings?.dailyGoalML = $0
                                    viewModel.saveChanges()
                                }
                            ), in: 500...5000, step: 250)
                            .tint(FluidicTheme.waterBlue)
                        }
                    }

                    // Cup size card
                    settingsCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Tap Size", systemImage: "cup.and.saucer.fill")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundStyle(FluidicTheme.textPrimary)

                            Text("Amount added per cup tap")
                                .font(.system(size: 13, weight: .regular, design: .rounded))
                                .foregroundStyle(FluidicTheme.textSecondary)

                            let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(cupSizes, id: \.self) { size in
                                    let isSelected = viewModel.settings?.cupSizeML == size
                                    Button {
                                        viewModel.settings?.cupSizeML = size
                                        viewModel.saveChanges()
                                    } label: {
                                        Text("\(Int(size))")
                                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                                            .foregroundStyle(isSelected ? .white : FluidicTheme.accent)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .fill(isSelected ? FluidicTheme.accent : FluidicTheme.waterBlue.opacity(0.12))
                                            )
                                    }
                                }
                            }
                        }
                    }

                    // Notifications card
                    settingsCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle(isOn: Binding(
                                get: { viewModel.settings?.notificationsEnabled ?? true },
                                set: {
                                    viewModel.settings?.notificationsEnabled = $0
                                    viewModel.saveChanges()
                                    if $0 {
                                        Task { await viewModel.setupNotifications() }
                                    }
                                }
                            )) {
                                Label("Reminders", systemImage: "bell.fill")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundStyle(FluidicTheme.textPrimary)
                            }
                            .tint(FluidicTheme.waterBlue)

                            if viewModel.settings?.notificationsEnabled == true {
                                // Reminder mode picker
                                Picker("Mode", selection: Binding(
                                    get: { viewModel.settings?.reminderMode ?? "smart" },
                                    set: {
                                        viewModel.settings?.reminderMode = $0
                                        viewModel.saveChanges()
                                        viewModel.scheduleReminders()
                                    }
                                )) {
                                    Text("Smart").tag("smart")
                                    Text("Fixed Interval").tag("fixed")
                                }
                                .pickerStyle(.segmented)

                                if viewModel.settings?.reminderMode == "fixed" {
                                    // Fixed interval stepper
                                    HStack {
                                        Text("Remind every")
                                            .font(.system(size: 14, weight: .medium, design: .rounded))
                                            .foregroundStyle(FluidicTheme.textSecondary)
                                        Spacer()
                                        Text(formatInterval(viewModel.settings?.reminderIntervalHours ?? 1.5))
                                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                                            .foregroundStyle(FluidicTheme.textPrimary)
                                    }

                                    Stepper(
                                        formatInterval(viewModel.settings?.reminderIntervalHours ?? 1.5),
                                        value: Binding(
                                            get: { viewModel.settings?.reminderIntervalHours ?? 1.5 },
                                            set: {
                                                viewModel.settings?.reminderIntervalHours = $0
                                                viewModel.saveChanges()
                                                viewModel.scheduleReminders()
                                            }
                                        ),
                                        in: 0.5...4.0,
                                        step: 0.5
                                    )
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .labelsHidden()
                                }

                                // Active hours (shown for both modes)
                                HStack {
                                    Text("Active hours")
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundStyle(FluidicTheme.textSecondary)
                                    Spacer()
                                    Text("\(viewModel.settings?.activeHoursStart ?? 8):00 - \(viewModel.settings?.activeHoursEnd ?? 22):00")
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                        .foregroundStyle(FluidicTheme.textPrimary)
                                }

                                HStack {
                                    Text("From")
                                        .font(.system(size: 13, design: .rounded))
                                        .foregroundStyle(FluidicTheme.textSecondary)
                                    Stepper("\(viewModel.settings?.activeHoursStart ?? 8):00", value: Binding(
                                        get: { viewModel.settings?.activeHoursStart ?? 8 },
                                        set: {
                                            viewModel.settings?.activeHoursStart = $0
                                            viewModel.saveChanges()
                                            viewModel.scheduleReminders()
                                        }
                                    ), in: 5...12)
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                }

                                HStack {
                                    Text("Until")
                                        .font(.system(size: 13, design: .rounded))
                                        .foregroundStyle(FluidicTheme.textSecondary)
                                    Stepper("\(viewModel.settings?.activeHoursEnd ?? 22):00", value: Binding(
                                        get: { viewModel.settings?.activeHoursEnd ?? 22 },
                                        set: {
                                            viewModel.settings?.activeHoursEnd = $0
                                            viewModel.saveChanges()
                                            viewModel.scheduleReminders()
                                        }
                                    ), in: 18...23)
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                }
                            }
                        }
                    }

                    // Language card
                    settingsCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Language", systemImage: "globe")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundStyle(FluidicTheme.textPrimary)

                            Picker("Language", selection: Binding(
                                    get: { viewModel.settings?.languageCode ?? "en" },
                                    set: { 
                                        viewModel.settings?.languageCode = $0
                                        viewModel.saveChanges()
                                    }
                                )) {
                                Text("English").tag("en")
                                Text("Čeština").tag("cs")
                            }
                            .pickerStyle(.segmented)
                        }
                    }

                    // Reset card
                    settingsCard {
                        Button {
                            showResetAlert = true
                        } label: {
                            HStack {
                                Label("Reset Today's Data", systemImage: "arrow.counterclockwise")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.red)
                                Spacer()
                            }
                        }
                    }
                    .alert("Reset Today's Data?", isPresented: $showResetAlert) {
                        Button("Cancel", role: .cancel) {}
                        Button("Reset", role: .destructive) {
                            viewModel.resetToday()
                        }
                    } message: {
                        Text("This will clear all water intake logged today. This cannot be undone.")
                    }

                    // App info
                    VStack(spacing: 4) {
                        Text("Fluidic v0.0.2")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(FluidicTheme.textSecondary)
                        Text("Stay hydrated")
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundStyle(FluidicTheme.textSecondary.opacity(0.6))
                    }
                    .padding(.top, 8)
                }
                .padding(.vertical)
            }
        }
    }

    private func formatInterval(_ hours: Double) -> String {
        if hours == Double(Int(hours)) {
            return "\(Int(hours))h"
        }
        let totalMinutes = Int(hours * 60)
        let h = totalMinutes / 60
        let m = totalMinutes % 60
        return h > 0 ? "\(h)h \(m)min" : "\(m)min"
    }

    @ViewBuilder
    private func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading) {
            content()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(FluidicTheme.cardBackground)
                .shadow(color: FluidicTheme.cardShadow, radius: 24, y: 8)
        )
        .padding(.horizontal)
    }
}
