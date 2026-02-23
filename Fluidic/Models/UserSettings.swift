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
    var totalXP: Int
    var currentLevel: Int
    var streakFreezeCount: Int
    var frozenDatesData: Data?
    var challengesCompleted: Int
    var lastStreakFreezeAwardedAt: Int // streak length when last freeze was awarded

    var frozenDates: [Date] {
        get {
            guard let data = frozenDatesData else { return [] }
            return (try? JSONDecoder().decode([Date].self, from: data)) ?? []
        }
        set {
            frozenDatesData = try? JSONEncoder().encode(newValue)
        }
    }

    init(
        dailyGoalML: Double = 2500,
        cupSizeML: Double = 250,
        activeHoursStart: Int = 8,
        activeHoursEnd: Int = 22,
        notificationsEnabled: Bool = true,
        languageCode: String = "en",
        reminderMode: String = "smart",
        reminderIntervalHours: Double = 1.5,
        hasCompletedOnboarding: Bool = false,
        totalXP: Int = 0,
        currentLevel: Int = 1,
        streakFreezeCount: Int = 0,
        frozenDatesData: Data? = nil,
        challengesCompleted: Int = 0,
        lastStreakFreezeAwardedAt: Int = 0
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
        self.totalXP = totalXP
        self.currentLevel = currentLevel
        self.streakFreezeCount = streakFreezeCount
        self.frozenDatesData = frozenDatesData
        self.challengesCompleted = challengesCompleted
        self.lastStreakFreezeAwardedAt = lastStreakFreezeAwardedAt
    }
}
