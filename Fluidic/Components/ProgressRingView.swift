import SwiftUI

struct ProgressRingView: View {
    let progress: Double
    var lineWidth: CGFloat = 10
    var size: CGFloat = 60

    var body: some View {
        ZStack {
            Circle()
                .stroke(FluidicTheme.lightBlue.opacity(0.3), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [FluidicTheme.secondaryBlue, FluidicTheme.waterBlue, FluidicTheme.accent],
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: progress)
        }
        .frame(width: size, height: size)
        .accessibilityLabel(String(localized: "Progress"))
        .accessibilityValue(String(localized: "\(Int(progress * 100)) percent"))
    }
}
