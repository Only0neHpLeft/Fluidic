import SwiftUI

struct QuickAddButton: View {
    let amount: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("+\(amount) ml")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(FluidicTheme.accent)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(FluidicTheme.waterBlue.opacity(0.15))
                )
        }
        .accessibilityLabel(String(localized: "Add \(amount) milliliters"))
    }
}
