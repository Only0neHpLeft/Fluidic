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
                        .fill(achievement.isUnlocked ? achievement.color : Color.gray.opacity(0.2))
                        .frame(width: 56, height: 56)

                    if achievement.isUnlocked {
                        if let text = achievement.textOverlay {
                            Text(text)
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        } else {
                            Image(systemName: achievement.iconName)
                                .font(.title2)
                                .foregroundStyle(.white)
                        }
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
