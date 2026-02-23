import SwiftUI
import UIKit

// Refined theme inspired by the clean, modern smart home structure in the design mockup.
enum FluidicTheme {
    // MARK: - Background
    
    // Very light off-white/gray background for light mode
    static let backgroundTop = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.10, green: 0.10, blue: 0.11, alpha: 1)   // #19191C
            : UIColor(red: 0.96, green: 0.97, blue: 0.98, alpha: 1)   // #F4F6F9
    })

    static let backgroundBottom = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.08, green: 0.08, blue: 0.09, alpha: 1)   // #141417
            : UIColor(red: 0.95, green: 0.96, blue: 0.99, alpha: 1)   // #F2F4FC
    })

    // MARK: - Primary Blues

    // A vibrant, popping blue similar to the main CTA button
    static let waterBlue = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.22, green: 0.51, blue: 0.96, alpha: 1)   // #3882F6
            : UIColor(red: 0.17, green: 0.51, blue: 0.96, alpha: 1)   // #2C82F5
    })

    static let waterBlueDark = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.15, green: 0.40, blue: 0.85, alpha: 1)   // #2666D9
            : UIColor(red: 0.10, green: 0.38, blue: 0.85, alpha: 1)   // #1A61D9
    })

    static let secondaryBlue = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.35, green: 0.60, blue: 0.96, alpha: 1)
            : UIColor(red: 0.38, green: 0.65, blue: 0.98, alpha: 1)
    })

    static let lightBlue = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.17, green: 0.51, blue: 0.96, alpha: 0.2)
            : UIColor(red: 0.17, green: 0.51, blue: 0.96, alpha: 0.1)
    })

    // MARK: - Accent
    static let accent = waterBlue

    // MARK: - Text
    
    // Very dark gray for sharp contrast, not pure black
    static let textPrimary = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1)
            : UIColor(red: 0.10, green: 0.11, blue: 0.12, alpha: 1)
    })

    static let textSecondary = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.60, green: 0.62, blue: 0.68, alpha: 1)
            : UIColor(red: 0.45, green: 0.48, blue: 0.53, alpha: 1)
    })

    // MARK: - Card

    static let cardBackground = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.15, green: 0.16, blue: 0.18, alpha: 1)
            : UIColor.white
    })

    static let cardShadow = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 0, alpha: 0.4)
            : UIColor(red: 0.20, green: 0.25, blue: 0.35, alpha: 0.05)
    })

    // MARK: - Success

    static let successGreen = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.18, green: 0.82, blue: 0.44, alpha: 1)   // #2ECC71
            : UIColor(red: 0.18, green: 0.82, blue: 0.44, alpha: 1)   // #2ECC71
    })

    // MARK: - Gradients

    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [backgroundTop, backgroundBottom],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var waterGradient: LinearGradient {
        LinearGradient(
            colors: [secondaryBlue, waterBlue, waterBlueDark],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
