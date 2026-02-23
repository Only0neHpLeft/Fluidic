import SwiftUI

struct OnboardingView: View {
    @Bindable var viewModel: WaterViewModel
    let onComplete: () -> Void

    @State private var currentPage = 0
    @State private var selectedGoal: Double = 2500
    @State private var selectedCupSize: Double = 250
    @State private var enableNotifications = true

    private let goalPresets: [Double] = [2000, 2500, 3000]
    private let cupSizes: [Double] = [100, 150, 200, 250, 330, 500]

    var body: some View {
        ZStack {
            FluidicTheme.backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress dots
                HStack(spacing: 8) {
                    ForEach(0..<4, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? FluidicTheme.waterBlue : FluidicTheme.textSecondary.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.top, 20)

                TabView(selection: $currentPage) {
                    welcomePage.tag(0)
                    goalPage.tag(1)
                    cupSizePage.tag(2)
                    notificationsPage.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentPage)
            }
        }
    }

    // MARK: - Welcome

    private var welcomePage: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "drop.fill")
                .font(.system(size: 80))
                .foregroundStyle(FluidicTheme.waterGradient)

            Text(String(localized: "Welcome to Fluidic"))
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(FluidicTheme.textPrimary)

            Text(String(localized: "Track your hydration, build healthy habits"))
                .font(.body)
                .foregroundStyle(FluidicTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()

            continueButton { currentPage = 1 }
                .padding(.bottom, 40)
        }
    }

    // MARK: - Goal

    private var goalPage: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "flag.fill")
                .font(.system(size: 60))
                .foregroundStyle(FluidicTheme.waterBlue)

            Text(String(localized: "Set Your Daily Goal"))
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(FluidicTheme.textPrimary)

            Text(String(localized: "\(Int(selectedGoal)) ml"))
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(FluidicTheme.waterBlue)
                .contentTransition(.numericText())

            Slider(value: $selectedGoal, in: 500...5000, step: 250)
                .tint(FluidicTheme.waterBlue)
                .padding(.horizontal, 40)

            HStack(spacing: 12) {
                ForEach(goalPresets, id: \.self) { preset in
                    Button {
                        withAnimation { selectedGoal = preset }
                    } label: {
                        Text("\(Int(preset))")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedGoal == preset ? FluidicTheme.waterBlue : FluidicTheme.cardBackground)
                            .foregroundStyle(selectedGoal == preset ? .white : FluidicTheme.textPrimary)
                            .clipShape(Capsule())
                    }
                }
            }

            Spacer()

            skipAndContinue { currentPage = 2 }
                .padding(.bottom, 40)
        }
    }

    // MARK: - Cup Size

    private var cupSizePage: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "cup.and.saucer.fill")
                .font(.system(size: 60))
                .foregroundStyle(FluidicTheme.waterBlue)

            Text(String(localized: "Choose Your Cup Size"))
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(FluidicTheme.textPrimary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                ForEach(cupSizes, id: \.self) { size in
                    Button {
                        withAnimation { selectedCupSize = size }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "drop.fill")
                                .font(.title3)
                                .scaleEffect(size / 250.0 * 0.8 + 0.4)
                            Text("\(Int(size)) ml")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(selectedCupSize == size ? FluidicTheme.waterBlue : FluidicTheme.cardBackground)
                        .foregroundStyle(selectedCupSize == size ? .white : FluidicTheme.textPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            skipAndContinue { currentPage = 3 }
                .padding(.bottom, 40)
        }
    }

    // MARK: - Notifications

    private var notificationsPage: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "bell.badge.fill")
                .font(.system(size: 60))
                .foregroundStyle(FluidicTheme.waterBlue)

            Text(String(localized: "Stay on Track"))
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(FluidicTheme.textPrimary)

            Text(String(localized: "Get reminders to drink water throughout the day"))
                .font(.body)
                .foregroundStyle(FluidicTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Toggle(String(localized: "Enable Reminders"), isOn: $enableNotifications)
                .padding(.horizontal, 40)
                .tint(FluidicTheme.waterBlue)

            Spacer()

            VStack(spacing: 12) {
                Button {
                    completeOnboarding()
                } label: {
                    Text(String(localized: "Get Started"))
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(FluidicTheme.waterBlue)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 40)

                Button {
                    enableNotifications = false
                    completeOnboarding()
                } label: {
                    Text(String(localized: "Skip"))
                        .font(.subheadline)
                        .foregroundStyle(FluidicTheme.textSecondary)
                }
            }
            .padding(.bottom, 40)
        }
    }

    // MARK: - Helpers

    private func completeOnboarding() {
        viewModel.settings?.dailyGoalML = selectedGoal
        viewModel.settings?.cupSizeML = selectedCupSize
        viewModel.settings?.notificationsEnabled = enableNotifications
        viewModel.settings?.hasCompletedOnboarding = true
        viewModel.saveChanges()

        if enableNotifications {
            Task {
                await viewModel.setupNotifications()
                viewModel.scheduleReminders()
            }
        }

        onComplete()
    }

    private func continueButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(String(localized: "Continue"))
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(FluidicTheme.waterBlue)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .padding(.horizontal, 40)
    }

    private func skipAndContinue(action: @escaping () -> Void) -> some View {
        VStack(spacing: 12) {
            continueButton(action: action)

            Button(action: action) {
                Text(String(localized: "Skip"))
                    .font(.subheadline)
                    .foregroundStyle(FluidicTheme.textSecondary)
            }
        }
    }
}
