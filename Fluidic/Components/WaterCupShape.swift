import SwiftUI

struct WaterCupShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let topWidth = rect.width * 0.9
        let bottomWidth = rect.width * 0.65
        let height = rect.height
        let cornerRadius: CGFloat = 20

        let topLeftX = (rect.width - topWidth) / 2
        let topRightX = topLeftX + topWidth
        let bottomLeftX = (rect.width - bottomWidth) / 2
        let bottomRightX = bottomLeftX + bottomWidth

        path.move(to: CGPoint(x: topLeftX, y: 0))
        path.addLine(to: CGPoint(x: topRightX, y: 0))
        path.addLine(to: CGPoint(x: bottomRightX, y: height - cornerRadius))

        path.addQuadCurve(
            to: CGPoint(x: bottomRightX - cornerRadius, y: height),
            control: CGPoint(x: bottomRightX, y: height)
        )

        path.addLine(to: CGPoint(x: bottomLeftX + cornerRadius, y: height))

        path.addQuadCurve(
            to: CGPoint(x: bottomLeftX, y: height - cornerRadius),
            control: CGPoint(x: bottomLeftX, y: height)
        )

        path.addLine(to: CGPoint(x: topLeftX, y: 0))

        path.closeSubpath()
        return path
    }
}
