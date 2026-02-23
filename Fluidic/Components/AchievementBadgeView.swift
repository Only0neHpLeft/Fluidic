import SwiftUI

struct AchievementBadgeView: View {
    let achievement: Achievement
    @State private var showDetail = false

    var body: some View {
        Button {
            if achievement.isUnlocked {
                showDetail = true
            }
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(achievement.isUnlocked ? FluidicTheme.waterBlue.opacity(0.15) : Color.gray.opacity(0.1))
                        .frame(width: 56, height: 56)

                    if achievement.isUnlocked {
                        Image(systemName: achievement.iconName)
                            .font(.title2)
                            .foregroundStyle(FluidicTheme.waterBlue)
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundStyle(FluidicTheme.textSecondary.opacity(0.5))
                    }
                }

                Text(achievement.isUnlocked ? achievement.title : "???")
                    .font(.caption2)
                    .foregroundStyle(achievement.isUnlocked ? FluidicTheme.textPrimary : FluidicTheme.textSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(achievement.isUnlocked ? achievement.title : String(localized: "Locked achievement"))
        .accessibilityHint(achievement.isUnlocked ? achievement.descriptionText : String(localized: "Keep tracking to unlock"))
        .alert(achievement.title, isPresented: $showDetail) {
            Button(String(localized: "OK"), role: .cancel) {}
        } message: {
            if let date = achievement.unlockedAt {
                Text("\(achievement.descriptionText)\n\n\(String(localized: "Unlocked:"))\n\(date.formatted(date: .abbreviated, time: .omitted))")
            }
        }
    }
}
