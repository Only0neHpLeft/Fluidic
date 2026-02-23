import SwiftUI

struct WaterCupView: View {
    let progress: Double // 0.0 to 1.0
    var onTap: () -> Void

    @State private var waveOffset: Double = 0
    @State private var tapScale: Double = 1.0

    private var fillProgress: Double {
        min(progress, 0.93)
    }

    private var waveAmplitude: Double {
        guard progress > 0.01 else { return 0 }
        if progress > 0.85 { return 4.0 * (1.0 - progress) * 5 }
        return 4.0
    }

    var body: some View {
        ZStack {
            // Cup outline
            WaterCupShape()
                .stroke(
                    FluidicTheme.secondaryBlue.opacity(0.5),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                )

            // Water fill
            if progress > 0.005 {
                WaterCupFillShape()
                    .fill(Color.clear)
                    .overlay(alignment: .bottom) {
                        GeometryReader { geometry in
                            let waterHeight = geometry.size.height * fillProgress

                            ZStack(alignment: .bottom) {
                                Rectangle()
                                    .fill(FluidicTheme.waterGradient)
                                    .frame(height: waterHeight)
                                    .overlay(alignment: .top) {
                                        WaveShape(
                                            offset: waveOffset,
                                            amplitude: waveAmplitude,
                                            frequency: 1.3,
                                            phase: 0
                                        )
                                        .fill(FluidicTheme.waterGradient)
                                        .frame(height: 16)
                                        .offset(y: -8)
                                    }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                        }
                    }
                    .clipShape(WaterCupFillShape())
            }

            // Percentage label
            Text("\(Int(progress * 100))%")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(progress > 0.45 ? .white : FluidicTheme.textPrimary)
                .contentTransition(.numericText())
        }
        .contentShape(Rectangle())
        .scaleEffect(tapScale)
        .onTapGesture {
            onTap()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                tapScale = 1.06
            }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5).delay(0.15)) {
                tapScale = 1.0
            }

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
