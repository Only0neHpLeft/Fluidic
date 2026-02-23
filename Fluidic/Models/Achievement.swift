import Foundation
import SwiftUI
import SwiftData

@Model
final class Achievement {
    #Unique<Achievement>([\.achievementId])

    var achievementId: String
    var title: String
    var descriptionText: String
    var iconName: String
    var category: String
    var colorHex: String
    var textOverlay: String?
    var unlockedAt: Date?

    var isUnlocked: Bool { unlockedAt != nil }

    var color: Color {
        let hex = colorHex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard let int = UInt64(hex, radix: 16) else { return .gray }
        let r = Double((int >> 16) & 0xFF) / 255.0
        let g = Double((int >> 8) & 0xFF) / 255.0
        let b = Double(int & 0xFF) / 255.0
        return Color(red: r, green: g, blue: b)
    }

    init(achievementId: String, title: String, descriptionText: String, iconName: String, category: String, colorHex: String = "#78909C", textOverlay: String? = nil, unlockedAt: Date? = nil) {
        self.achievementId = achievementId
        self.title = title
        self.descriptionText = descriptionText
        self.iconName = iconName
        self.category = category
        self.colorHex = colorHex
        self.textOverlay = textOverlay
        self.unlockedAt = unlockedAt
    }
}
