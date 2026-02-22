import Foundation
import SwiftData

@Model
final class UserSettings {
    var dailyGoalML: Double
    var cupSizeML: Double
    var activeHoursStart: Int
    var activeHoursEnd: Int
    var notificationsEnabled: Bool
    var healthKitEnabled: Bool

    init(
        dailyGoalML: Double = 2500,
        cupSizeML: Double = 250,
        activeHoursStart: Int = 8,
        activeHoursEnd: Int = 22,
        notificationsEnabled: Bool = true,
        healthKitEnabled: Bool = false
    ) {
        self.dailyGoalML = dailyGoalML
        self.cupSizeML = cupSizeML
        self.activeHoursStart = activeHoursStart
        self.activeHoursEnd = activeHoursEnd
        self.notificationsEnabled = notificationsEnabled
        self.healthKitEnabled = healthKitEnabled
    }
}
