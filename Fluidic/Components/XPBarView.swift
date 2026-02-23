import SwiftUI

struct XPBarView: View {
    let totalXP: Int
    let currentLevel: Int
    let isCS: Bool

    private var progress: Double {
        XPManager.progressToNextLevel(totalXP: totalXP, currentLevel: currentLevel)
    }

    private var levelTitle: String {
        XPManager.title(for: currentLevel, isCS: isCS)
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(String(localized: "Level \(currentLevel)"))
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(FluidicTheme.textPrimary)

                Text("• \(levelTitle)")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(FluidicTheme.textSecondary)

                Spacer()

                Text("\(totalXP) XP")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(FluidicTheme.waterBlue)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(FluidicTheme.lightBlue.opacity(0.3))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(FluidicTheme.waterBlue)
                        .frame(width: geometry.size.width * progress)
                        .animation(.spring(response: 0.5), value: progress)
                }
            }
            .frame(height: 8)
        }
        .padding(.horizontal)
    }
}
