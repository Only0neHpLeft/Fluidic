import SwiftUI

struct LevelUpView: View {
    let level: Int
    let isCS: Bool
    let onDismiss: () -> Void
    @State private var opacity = 0.0

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 16) {
                Text(String(localized: "Level Up!"))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(FluidicTheme.textPrimary)

                Text(String(localized: "Level \(level)"))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(FluidicTheme.waterBlue)

                Text(XPManager.title(for: level, isCS: isCS))
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundStyle(FluidicTheme.textSecondary)

                Button(String(localized: "Continue")) {
                    onDismiss()
                }
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 12).fill(FluidicTheme.accent))
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
            withAnimation(.easeIn(duration: 0.3)) { opacity = 1 }
        }
    }
}
