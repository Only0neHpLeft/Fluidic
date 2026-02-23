import SwiftUI

struct HomeView: View {
    @Bindable var viewModel: WaterViewModel

    var body: some View {
        ZStack {
            FluidicTheme.backgroundGradient
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Greeting header
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.greetingKey)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(FluidicTheme.textPrimary)
                        Text(Date.now, format: .dateTime.weekday(.wide).month(.wide).day())
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(FluidicTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

                    // Water cup
                    WaterCupView(progress: viewModel.progress) {
                        viewModel.addWater()
                    }
                    .frame(width: 220, height: 300)
                    .padding(.vertical, 8)

                    // Progress text
                    VStack(spacing: 8) {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(formatML(viewModel.todayTotal))
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(FluidicTheme.textPrimary)
                                .contentTransition(.numericText())
                            Text("/ \(formatML(viewModel.dailyGoal))")
                                .font(.system(size: 18, weight: .medium, design: .rounded))
                                .foregroundStyle(FluidicTheme.textSecondary)
                        }
                        Text("Tap the cup to add \(Int(viewModel.cupSize)) ml", comment: "Hint below water progress")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(FluidicTheme.textSecondary)
                    }

                    // XP progress
                    XPBarView(
                        totalXP: viewModel.settings?.totalXP ?? 0,
                        currentLevel: viewModel.settings?.currentLevel ?? 1,
                        isCS: viewModel.appLocale.language.languageCode?.identifier == "cs"
                    )

                    // Quick add buttons
                    HStack(spacing: 10) {
                        QuickAddButton(amount: 100) { viewModel.addWater(amount: 100) }
                        QuickAddButton(amount: 250) { viewModel.addWater(amount: 250) }
                        QuickAddButton(amount: 500) { viewModel.addWater(amount: 500) }
                    }

                    // Daily challenge
                    if let challenge = viewModel.challengeManager.todayChallenge {
                        DailyChallengeCard(
                            challengeText: viewModel.challengeManager.challengeText(
                                isCS: viewModel.appLocale.language.languageCode?.identifier == "cs"
                            ),
                            isCompleted: challenge.completed
                        )
                    }

                    // Today's log card
                    if !viewModel.todayIntakes.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Today's Log")
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .foregroundStyle(FluidicTheme.textPrimary)

                            ForEach(viewModel.todayIntakes.suffix(5).reversed(), id: \.id) { intake in
                                HStack {
                                    Image(systemName: "drop.fill")
                                        .foregroundStyle(FluidicTheme.waterBlue)
                                        .font(.system(size: 14))
                                    Text("\(Int(intake.amount)) ml")
                                        .font(.system(size: 15, weight: .medium, design: .rounded))
                                        .foregroundStyle(FluidicTheme.textPrimary)
                                    Spacer()
                                    Text(intake.timestamp.formatted(.dateTime.hour().minute()))
                                        .font(.system(size: 13, weight: .regular, design: .rounded))
                                        .foregroundStyle(FluidicTheme.textSecondary)
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(FluidicTheme.cardBackground)
                                .shadow(color: FluidicTheme.cardShadow, radius: 24, y: 8)
                        )
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }

            // Celebration overlay
            if viewModel.showCelebration {
                CelebrationView {
                    viewModel.showCelebration = false
                }
            }

            // Achievement toast
            if let achievement = viewModel.achievementManager.newlyUnlocked {
                AchievementToastView(achievement: achievement) {
                    viewModel.achievementManager.dismissToast()
                }
            }

            // Level up celebration
            if viewModel.xpManager.showLevelUp {
                LevelUpView(level: viewModel.xpManager.newLevel, isCS: viewModel.appLocale.language.languageCode?.identifier == "cs") {
                    viewModel.xpManager.dismissLevelUp()
                }
            }
        }
    }

    private func formatML(_ ml: Double) -> String {
        if ml >= 1000 {
            return String(format: "%.1f L", ml / 1000)
        }
        return "\(Int(ml)) ml"
    }
}

struct CelebrationView: View {
    var onDismiss: () -> Void
    @State private var opacity = 0.0

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 16) {
                Text("\u{1F389}")
                    .font(.system(size: 64))
                Text("Goal Reached!")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(FluidicTheme.textPrimary)
                Text("Amazing work staying hydrated today!")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(FluidicTheme.textSecondary)

                Button("Continue") {
                    onDismiss()
                }
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(FluidicTheme.accent)
                )
                .padding(.top, 8)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 32)
                    .fill(FluidicTheme.cardBackground)
                    .shadow(color: FluidicTheme.cardShadow, radius: 32, y: 16)
            )
            .padding(40)
        }
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeIn(duration: 0.3)) {
                opacity = 1
            }
        }
    }
}
