import Foundation
import SwiftData

@Model
final class Achievement {
    #Unique<Achievement>([\.achievementId])

    var achievementId: String
    var title: String
    var descriptionText: String
    var iconName: String
    var category: String
    var unlockedAt: Date?

    var isUnlocked: Bool { unlockedAt != nil }

    init(achievementId: String, title: String, descriptionText: String, iconName: String, category: String, unlockedAt: Date? = nil) {
        self.achievementId = achievementId
        self.title = title
        self.descriptionText = descriptionText
        self.iconName = iconName
        self.category = category
        self.unlockedAt = unlockedAt
    }
}
