import SwiftUI

struct WaterCupView: View {
    let progress: Double // 0.0 to 1.0
    var onTap: () -> Void

    @State private var waveOffset: Double = 0
    @State private var tapScale: Double = 1.0

    var body: some View {
        ZStack {
            // Cup outline (glass effect)
            WaterCupShape()
                .stroke(
                    FluidicTheme.secondaryBlue,
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )

            // Water fill
            WaterCupShape()
                .fill(Color.clear)
                .overlay(alignment: .bottom) {
                    GeometryReader { geometry in
                        let fillHeight = geometry.size.height * progress

                        ZStack(alignment: .top) {
                            // Solid water body
                            Rectangle()
                                .fill(FluidicTheme.waterGradient)
                                .frame(height: fillHeight)

                            // Wave on top of water
                            WaveShape(offset: waveOffset, amplitude: progress > 0.02 ? 4 : 0)
                                .fill(FluidicTheme.waterGradient)
                                .frame(height: 20)
                                .offset(y: -10)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    }
                }
                .clipShape(WaterCupShape())

            // Glass highlight (reflection effect)
            WaterCupShape()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.3),
                            Color.white.opacity(0.0),
                            Color.white.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Percentage label centered
            VStack(spacing: 4) {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(progress > 0.5 ? .white : FluidicTheme.textPrimary)
                    .contentTransition(.numericText())
            }
        }
        .scaleEffect(tapScale)
        .onTapGesture {
            onTap()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                tapScale = 1.08
            }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5).delay(0.15)) {
                tapScale = 1.0
            }

            // Haptic
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
        }
        .onAppear {
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                waveOffset = 1
            }
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: progress)
    }
}
