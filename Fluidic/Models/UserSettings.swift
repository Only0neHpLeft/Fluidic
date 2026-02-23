import Foundation
import SwiftData

@Model
final class UserSettings {
    var dailyGoalML: Double
    var cupSizeML: Double
    var activeHoursStart: Int
    var activeHoursEnd: Int
    var notificationsEnabled: Bool
    var languageCode: String
    var reminderMode: String          // "smart" or "fixed"
    var reminderIntervalHours: Double // 0.5 - 4.0
    var hasCompletedOnboarding: Bool

    init(
        dailyGoalML: Double = 2500,
        cupSizeML: Double = 250,
        activeHoursStart: Int = 8,
        activeHoursEnd: Int = 22,
        notificationsEnabled: Bool = true,
        languageCode: String = "en",
        reminderMode: String = "smart",
        reminderIntervalHours: Double = 1.5,
        hasCompletedOnboarding: Bool = false
    ) {
        self.dailyGoalML = dailyGoalML
        self.cupSizeML = cupSizeML
        self.activeHoursStart = activeHoursStart
        self.activeHoursEnd = activeHoursEnd
        self.notificationsEnabled = notificationsEnabled
        self.languageCode = languageCode
        self.reminderMode = reminderMode
        self.reminderIntervalHours = reminderIntervalHours
        self.hasCompletedOnboarding = hasCompletedOnboarding
    }
}
