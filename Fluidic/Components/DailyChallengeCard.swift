import SwiftUI

struct DailyChallengeCard: View {
    let challengeText: String
    let isCompleted: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "flag.fill")
                .font(.title3)
                .foregroundStyle(isCompleted ? FluidicTheme.successGreen : FluidicTheme.waterBlue)

            VStack(alignment: .leading, spacing: 2) {
                Text(String(localized: "Daily Challenge"))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(FluidicTheme.textSecondary)

                Text(challengeText)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(FluidicTheme.textPrimary)
            }

            Spacer()

            if isCompleted {
                Text("+75 XP")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(FluidicTheme.successGreen)
            }
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
