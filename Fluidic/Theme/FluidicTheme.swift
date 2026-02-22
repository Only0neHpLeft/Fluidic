import SwiftUI

enum FluidicTheme {
    // Background
    static let backgroundTop = Color(red: 0.91, green: 0.96, blue: 0.99)    // #E8F4FD
    static let backgroundBottom = Color(red: 0.94, green: 0.97, blue: 1.0)   // #F0F8FF

    // Primary
    static let waterBlue = Color(red: 0.26, green: 0.65, blue: 0.96)         // #42A5F5
    static let waterBlueDark = Color(red: 0.12, green: 0.53, blue: 0.90)     // #1E88E5
    static let secondaryBlue = Color(red: 0.56, green: 0.79, blue: 0.98)     // #90CAF9
    static let lightBlue = Color(red: 0.73, green: 0.87, blue: 0.98)         // #BBDEFB

    // Accent
    static let accent = Color(red: 0.12, green: 0.53, blue: 0.90)            // #1E88E5

    // Text
    static let textPrimary = Color(red: 0.10, green: 0.10, blue: 0.18)       // #1A1A2E
    static let textSecondary = Color(red: 0.42, green: 0.48, blue: 0.55)     // #6B7B8D

    // Card
    static let cardBackground = Color.white
    static let cardShadow = Color.black.opacity(0.06)

    // Success
    static let successGreen = Color(red: 0.40, green: 0.73, blue: 0.42)      // #66BB6A

    // Background gradient
    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [backgroundTop, backgroundBottom],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // Water gradient (used inside the cup)
    static var waterGradient: LinearGradient {
        LinearGradient(
            colors: [secondaryBlue, waterBlue, waterBlueDark],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
