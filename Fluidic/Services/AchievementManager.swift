import Foundation
import SwiftData

@Observable
final class AchievementManager {

    private var modelContext: ModelContext?

    /// The most recently unlocked achievement, for toast display
    var newlyUnlocked: Achievement?

    struct AchievementDefinition {
        let id: String
        let titleEN: String
        let titleCS: String
        let descEN: String
        let descCS: String
        let icon: String
        let category: String
    }

    static let definitions: [AchievementDefinition] = [
        AchievementDefinition(id: "first_sip", titleEN: "First Sip", titleCS: "Prvn\u{00ED} dou\u{0161}ek", descEN: "Log your first water intake", descCS: "Zaznamenejte sv\u{016F}j prvn\u{00ED} p\u{0159}\u{00ED}jem vody", icon: "drop.fill", category: "hydration"),
        AchievementDefinition(id: "goal_reached", titleEN: "Daily Champion", titleCS: "Denn\u{00ED} \u{0161}ampion", descEN: "Reach your daily goal for the first time", descCS: "Poprv\u{00E9} dos\u{00E1}hn\u{011B}te denn\u{00ED}ho c\u{00ED}le", icon: "trophy.fill", category: "hydration"),
        AchievementDefinition(id: "streak_3", titleEN: "Consistent", titleCS: "Vytrval\u{00FD}", descEN: "Maintain a 3-day streak", descCS: "Udr\u{017E}ujte 3denn\u{00ED} s\u{00E9}rii", icon: "flame.fill", category: "streak"),
        AchievementDefinition(id: "streak_7", titleEN: "Week Warrior", titleCS: "T\u{00FD}denn\u{00ED} bojovn\u{00ED}k", descEN: "Maintain a 7-day streak", descCS: "Udr\u{017E}ujte 7denn\u{00ED} s\u{00E9}rii", icon: "flame.fill", category: "streak"),
        AchievementDefinition(id: "streak_30", titleEN: "Monthly Master", titleCS: "M\u{011B}s\u{00ED}\u{010D}n\u{00ED} mistr", descEN: "Maintain a 30-day streak", descCS: "Udr\u{017E}ujte 30denn\u{00ED} s\u{00E9}rii", icon: "star.fill", category: "streak"),
        AchievementDefinition(id: "early_bird", titleEN: "Early Bird", titleCS: "Rann\u{00ED} pt\u{00E1}\u{010D}e", descEN: "Log water before 8 AM", descCS: "Zaznamenejte vodu p\u{0159}ed 8:00", icon: "sunrise.fill", category: "milestone"),
        AchievementDefinition(id: "night_owl", titleEN: "Night Owl", titleCS: "No\u{010D}n\u{00ED} sova", descEN: "Log water after 10 PM", descCS: "Zaznamenejte vodu po 22:00", icon: "moon.fill", category: "milestone"),
        AchievementDefinition(id: "big_gulp", titleEN: "Big Gulp", titleCS: "Velk\u{00FD} dou\u{0161}ek", descEN: "Log 500 ml or more in one entry", descCS: "Zaznamenejte 500 ml nebo v\u{00ED}ce najednou", icon: "drop.triangle.fill", category: "hydration"),
        AchievementDefinition(id: "overachiever", titleEN: "Overachiever", titleCS: "P\u{0159}ebor\u{00ED}k", descEN: "Reach 150% of your daily goal", descCS: "Dos\u{00E1}hn\u{011B}te 150 % denn\u{00ED}ho c\u{00ED}le", icon: "bolt.fill", category: "hydration"),
        AchievementDefinition(id: "centurion", titleEN: "Centurion", titleCS: "Centurion", descEN: "Log 100 total water entries", descCS: "Zaznamenejte celkem 100 p\u{0159}\u{00ED}jm\u{016F} vody", icon: "100.circle.fill", category: "milestone"),
    ]

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        seedAchievementsIfNeeded()
    }

    /// Create achievement records on first launch
    private func seedAchievementsIfNeeded() {
        guard let modelContext else { return }
        let descriptor = FetchDescriptor<Achievement>()
        let existing = (try? modelContext.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }

        for def in Self.definitions {
            let achievement = Achievement(
                achievementId: def.id,
                title: def.titleEN,
                descriptionText: def.descEN,
                iconName: def.icon,
                category: def.category
            )
            modelContext.insert(achievement)
        }
        try? modelContext.save()
    }

    /// Call after every addWater to check unlock conditions
    func checkAchievements(
        todayTotal: Double,
        dailyGoal: Double,
        lastIntakeAmount: Double,
        streak: Int,
        totalEntries: Int,
        intakeHour: Int,
        locale: Locale
    ) {
        guard let modelContext else { return }
        let descriptor = FetchDescriptor<Achievement>(predicate: #Predicate { $0.unlockedAt == nil })
        guard let locked = try? modelContext.fetch(descriptor) else { return }

        let isCS = locale.language.languageCode?.identifier == "cs"

        for achievement in locked {
            var shouldUnlock = false

            switch achievement.achievementId {
            case "first_sip":
                shouldUnlock = true
            case "goal_reached":
                shouldUnlock = todayTotal >= dailyGoal
            case "streak_3":
                shouldUnlock = streak >= 3
            case "streak_7":
                shouldUnlock = streak >= 7
            case "streak_30":
                shouldUnlock = streak >= 30
            case "early_bird":
                shouldUnlock = intakeHour < 8
            case "night_owl":
                shouldUnlock = intakeHour >= 22
            case "big_gulp":
                shouldUnlock = lastIntakeAmount >= 500
            case "overachiever":
                shouldUnlock = todayTotal >= dailyGoal * 1.5
            case "centurion":
                shouldUnlock = totalEntries >= 100
            default:
                break
            }

            if shouldUnlock {
                achievement.unlockedAt = Date()
                if isCS, let def = Self.definitions.first(where: { $0.id == achievement.achievementId }) {
                    achievement.title = def.titleCS
                    achievement.descriptionText = def.descCS
                } else if let def = Self.definitions.first(where: { $0.id == achievement.achievementId }) {
                    achievement.title = def.titleEN
                    achievement.descriptionText = def.descEN
                }
                newlyUnlocked = achievement
            }
        }

        try? modelContext.save()
    }

    /// Fetch all achievements sorted by category
    func allAchievements() -> [Achievement] {
        guard let modelContext else { return [] }
        let descriptor = FetchDescriptor<Achievement>(sortBy: [SortDescriptor(\.category), SortDescriptor(\.achievementId)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    /// Count of total entries (for centurion check)
    func totalEntryCount() -> Int {
        guard let modelContext else { return 0 }
        let descriptor = FetchDescriptor<WaterIntake>()
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }

    /// Dismiss the toast
    func dismissToast() {
        newlyUnlocked = nil
    }
}
