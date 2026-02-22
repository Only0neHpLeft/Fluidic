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
                                    set: { viewModel.settings?.dailyGoalML = $0 }
                                ), in: 500...5000, step: 250)
                                .labelsHidden()
                            }

                            Slider(value: Binding(
                                get: { viewModel.settings?.dailyGoalML ?? 2500 },
                                set: { viewModel.settings?.dailyGoalML = $0 }
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

                            HStack(spacing: 8) {
                                ForEach(cupSizes, id: \.self) { size in
                                    let isSelected = viewModel.settings?.cupSizeML == size
                                    Button {
                                        viewModel.settings?.cupSizeML = size
                                    } label: {
                                        Text("\(Int(size))")
                                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                                            .foregroundStyle(isSelected ? .white : FluidicTheme.accent)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(
                                                RoundedRectangle(cornerRadius: 10)
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
                                    if $0 {
                                        Task { await viewModel.setupNotifications() }
                                    }
                                }
                            )) {
                                Label("Smart Reminders", systemImage: "bell.fill")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundStyle(FluidicTheme.textPrimary)
                            }
                            .tint(FluidicTheme.waterBlue)

                            if viewModel.settings?.notificationsEnabled == true {
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
                                        set: { viewModel.settings?.activeHoursStart = $0 }
                                    ), in: 5...12)
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                }

                                HStack {
                                    Text("Until")
                                        .font(.system(size: 13, design: .rounded))
                                        .foregroundStyle(FluidicTheme.textSecondary)
                                    Stepper("\(viewModel.settings?.activeHoursEnd ?? 22):00", value: Binding(
                                        get: { viewModel.settings?.activeHoursEnd ?? 22 },
                                        set: { viewModel.settings?.activeHoursEnd = $0 }
                                    ), in: 18...23)
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                }
                            }
                        }
                    }

                    // HealthKit card
                    settingsCard {
                        Toggle(isOn: Binding(
                            get: { viewModel.settings?.healthKitEnabled ?? false },
                            set: {
                                viewModel.settings?.healthKitEnabled = $0
                                if $0 {
                                    Task { await viewModel.setupHealthKit() }
                                }
                            }
                        )) {
                            VStack(alignment: .leading, spacing: 4) {
                                Label("Apple Health", systemImage: "heart.fill")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundStyle(FluidicTheme.textPrimary)
                                Text("Sync water intake to Health app")
                                    .font(.system(size: 13, weight: .regular, design: .rounded))
                                    .foregroundStyle(FluidicTheme.textSecondary)
                            }
                        }
                        .tint(FluidicTheme.waterBlue)
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
                        Text("Fluidic v1.0")
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

    @ViewBuilder
    private func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading) {
            content()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(FluidicTheme.cardBackground)
                .shadow(color: FluidicTheme.cardShadow, radius: 8, y: 4)
        )
        .padding(.horizontal)
    }
}
