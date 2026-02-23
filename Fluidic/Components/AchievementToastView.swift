import SwiftUI

struct AchievementToastView: View {
    let achievement: Achievement
    let onDismiss: () -> Void

    @State private var isVisible = false

    var body: some View {
        VStack {
            Spacer()

            if isVisible {
                HStack(spacing: 12) {
                    Image(systemName: achievement.iconName)
                        .font(.title2)
                        .foregroundStyle(FluidicTheme.waterBlue)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(String(localized: "Achievement Unlocked!"))
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(FluidicTheme.textSecondary)

                        Text(achievement.title)
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(FluidicTheme.textPrimary)
                    }

                    Spacer()
                }
                .padding()
                .background(FluidicTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: FluidicTheme.cardShadow, radius: 8, y: 4)
                .padding(.horizontal)
                .padding(.bottom, 32)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                isVisible = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(.easeOut(duration: 0.3)) {
                    isVisible = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    onDismiss()
                }
            }
        }
        .accessibilityLabel(String(localized: "Achievement unlocked: \(achievement.title)"))
    }
}
