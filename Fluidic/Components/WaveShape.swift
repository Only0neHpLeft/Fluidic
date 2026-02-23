import SwiftUI

struct WaveShape: Shape {
    var offset: Double
    var amplitude: Double
    var frequency: Double = 1.0
    var phase: Double = 0.0

    var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(offset, amplitude) }
        set {
            offset = newValue.first
            amplitude = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midHeight = height * 0.5

        path.move(to: CGPoint(x: 0, y: midHeight))

        for x in stride(from: 0, through: width, by: 1) {
            let relativeX = x / width
            let sine = sin((relativeX * frequency + offset + phase) * 2 * .pi)
            let y = midHeight + sine * amplitude
            path.addLine(to: CGPoint(x: x, y: y))
        }

        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()

        return path
    }
}
