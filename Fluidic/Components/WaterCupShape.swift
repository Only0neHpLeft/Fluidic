import SwiftUI

/// A realistic glass tumbler shape with a visible rim/lip at the top.
struct WaterCupShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let w = rect.width
        let h = rect.height

        // Rim dimensions
        let rimHeight: CGFloat = h * 0.04
        let rimOuterWidth = w * 0.92
        let rimInnerWidth = w * 0.88

        // Body dimensions
        let bodyBottomWidth = w * 0.62
        let bodyTop = rimHeight
        let bodyBottom = h
        let cornerRadius: CGFloat = min(w, h) * 0.06

        // Center offsets
        let rimOuterLeft = (w - rimOuterWidth) / 2
        let rimOuterRight = rimOuterLeft + rimOuterWidth
        let rimInnerLeft = (w - rimInnerWidth) / 2
        let rimInnerRight = rimInnerLeft + rimInnerWidth
        let bodyBottomLeft = (w - bodyBottomWidth) / 2
        let bodyBottomRight = bodyBottomLeft + bodyBottomWidth

        // Start at top-left rim outer edge
        path.move(to: CGPoint(x: rimOuterLeft, y: 0))

        // Rim top edge
        path.addLine(to: CGPoint(x: rimOuterRight, y: 0))

        // Rim right side down to body
        path.addLine(to: CGPoint(x: rimInnerRight, y: bodyTop))

        // Right body wall tapers inward to bottom
        path.addLine(to: CGPoint(x: bodyBottomRight, y: bodyBottom - cornerRadius))

        // Bottom-right corner
        path.addQuadCurve(
            to: CGPoint(x: bodyBottomRight - cornerRadius, y: bodyBottom),
            control: CGPoint(x: bodyBottomRight, y: bodyBottom)
        )

        // Bottom edge
        path.addLine(to: CGPoint(x: bodyBottomLeft + cornerRadius, y: bodyBottom))

        // Bottom-left corner
        path.addQuadCurve(
            to: CGPoint(x: bodyBottomLeft, y: bodyBottom - cornerRadius),
            control: CGPoint(x: bodyBottomLeft, y: bodyBottom)
        )

        // Left body wall back up
        path.addLine(to: CGPoint(x: rimInnerLeft, y: bodyTop))

        // Rim left side back to start
        path.addLine(to: CGPoint(x: rimOuterLeft, y: 0))

        path.closeSubpath()
        return path
    }
}

/// The inner fill area of the cup (excludes the rim area so water stays below the lip).
struct WaterCupFillShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let w = rect.width
        let h = rect.height

        let rimHeight: CGFloat = h * 0.04
        let rimInnerWidth = w * 0.88
        let bodyBottomWidth = w * 0.62
        let cornerRadius: CGFloat = min(w, h) * 0.06

        // Fill area starts just below the rim
        let fillTop = rimHeight + 1  // 1pt below rim
        let fillBottom = h

        // Calculate widths at fill top using linear interpolation
        let totalBodyHeight = fillBottom - rimHeight
        let fillProgress = (fillTop - rimHeight) / totalBodyHeight
        let topWidth = rimInnerWidth - (rimInnerWidth - bodyBottomWidth) * fillProgress
        let topLeft = (w - topWidth) / 2
        let topRight = topLeft + topWidth

        let bottomLeft = (w - bodyBottomWidth) / 2
        let bottomRight = bottomLeft + bodyBottomWidth

        path.move(to: CGPoint(x: topLeft, y: fillTop))
        path.addLine(to: CGPoint(x: topRight, y: fillTop))
        path.addLine(to: CGPoint(x: bottomRight, y: fillBottom - cornerRadius))

        path.addQuadCurve(
            to: CGPoint(x: bottomRight - cornerRadius, y: fillBottom),
            control: CGPoint(x: bottomRight, y: fillBottom)
        )

        path.addLine(to: CGPoint(x: bottomLeft + cornerRadius, y: fillBottom))

        path.addQuadCurve(
            to: CGPoint(x: bottomLeft, y: fillBottom - cornerRadius),
            control: CGPoint(x: bottomLeft, y: fillBottom)
        )

        path.addLine(to: CGPoint(x: topLeft, y: fillTop))
        path.closeSubpath()
        return path
    }
}
