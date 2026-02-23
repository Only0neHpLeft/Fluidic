import Foundation
import SwiftData

@Observable
final class AchievementManager {

    private var modelContext: ModelContext?
    private var settings: UserSettings?

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
        let colorHex: String
        let textOverlay: String?
    }

    static let definitions: [AchievementDefinition] = [
        AchievementDefinition(id: "first_sip", titleEN: "First Sip", titleCS: "První doušek", descEN: "Log your first water intake", descCS: "Zaznamenejte svůj první příjem vody", icon: "drop.fill", category: "hydration", colorHex: "#4FC3F7", textOverlay: nil),
        AchievementDefinition(id: "goal_reached", titleEN: "Daily Champion", titleCS: "Denní šampion", descEN: "Reach your daily goal for the first time", descCS: "Poprvé dosáhněte denního cíle", icon: "trophy.fill", category: "hydration", colorHex: "#FFD700", textOverlay: nil),
        AchievementDefinition(id: "streak_3", titleEN: "Consistent", titleCS: "Vytrvalý", descEN: "Maintain a 3-day streak", descCS: "Udržujte 3denní sérii", icon: "flame.fill", category: "streak", colorHex: "#FF7043", textOverlay: nil),
        AchievementDefinition(id: "streak_7", titleEN: "Week Warrior", titleCS: "Týdenní bojovník", descEN: "Maintain a 7-day streak", descCS: "Udržujte 7denní sérii", icon: "flame.fill", category: "streak", colorHex: "#FF5722", textOverlay: nil),
        AchievementDefinition(id: "streak_14", titleEN: "Two Weeks Strong", titleCS: "Dva týdny v řadě", descEN: "Maintain a 14-day streak", descCS: "Udržujte 14denní sérii", icon: "flame.fill", category: "streak", colorHex: "#F44336", textOverlay: nil),
        AchievementDefinition(id: "streak_30", titleEN: "Monthly Master", titleCS: "Měsíční mistr", descEN: "Maintain a 30-day streak", descCS: "Udržujte 30denní sérii", icon: "star.fill", category: "streak", colorHex: "#E91E63", textOverlay: nil),
        AchievementDefinition(id: "streak_60", titleEN: "Unstoppable", titleCS: "Nezastavitelný", descEN: "Maintain a 60-day streak", descCS: "Udržujte 60denní sérii", icon: "bolt.circle.fill", category: "streak", colorHex: "#D32F2F", textOverlay: nil),
        AchievementDefinition(id: "early_bird", titleEN: "Early Bird", titleCS: "Ranní ptáče", descEN: "Log water before 8 AM", descCS: "Zaznamenejte vodu před 8:00", icon: "sunrise.fill", category: "milestone", colorHex: "#FFA726", textOverlay: nil),
        AchievementDefinition(id: "night_owl", titleEN: "Night Owl", titleCS: "Noční sova", descEN: "Log water after 10 PM", descCS: "Zaznamenejte vodu po 22:00", icon: "moon.fill", category: "milestone", colorHex: "#5C6BC0", textOverlay: nil),
        AchievementDefinition(id: "midnight_sip", titleEN: "Midnight Sip", titleCS: "Půlnoční doušek", descEN: "Log water between midnight and 4 AM", descCS: "Zaznamenejte vodu mezi půlnocí a 4:00", icon: "moon.stars.fill", category: "milestone", colorHex: "#283593", textOverlay: nil),
        AchievementDefinition(id: "big_gulp", titleEN: "Big Gulp", titleCS: "Velký doušek", descEN: "Log 500 ml or more in one entry", descCS: "Zaznamenejte 500 ml nebo více najednou", icon: "drop.triangle.fill", category: "hydration", colorHex: "#26C6DA", textOverlay: nil),
        AchievementDefinition(id: "hydration_1L", titleEN: "Liter Legend", titleCS: "Litrová legenda", descEN: "Log 1000 ml in one day", descCS: "Zaznamenejte 1000 ml za den", icon: "drop.fill", category: "hydration", colorHex: "#29B6F6", textOverlay: "1L"),
        AchievementDefinition(id: "hydration_5L", titleEN: "Ocean Mode", titleCS: "Oceánový mód", descEN: "Log 5000 ml in one day", descCS: "Zaznamenejte 5000 ml za den", icon: "water.waves", category: "hydration", colorHex: "#0277BD", textOverlay: nil),
        AchievementDefinition(id: "overachiever", titleEN: "Overachiever", titleCS: "Přeborník", descEN: "Reach 150% of your daily goal", descCS: "Dosáhněte 150 % denního cíle", icon: "bolt.fill", category: "hydration", colorHex: "#AB47BC", textOverlay: nil),
        AchievementDefinition(id: "double_goal", titleEN: "Double Down", titleCS: "Dvojnásobek", descEN: "Reach 200% of your daily goal", descCS: "Dosáhněte 200 % denního cíle", icon: "bolt.fill", category: "hydration", colorHex: "#7E57C2", textOverlay: "2x"),
        AchievementDefinition(id: "centurion", titleEN: "Centurion", titleCS: "Centurion", descEN: "Log 100 total water entries", descCS: "Zaznamenejte celkem 100 příjmů vody", icon: "circle.fill", category: "milestone", colorHex: "#EC407A", textOverlay: "100"),
        AchievementDefinition(id: "entries_10", titleEN: "Getting Started", titleCS: "Začátečník", descEN: "Log 10 total entries", descCS: "Zaznamenejte celkem 10 příjmů", icon: "circle.fill", category: "milestone", colorHex: "#78909C", textOverlay: "10"),
        AchievementDefinition(id: "entries_500", titleEN: "Half Thousand", titleCS: "Půl tisíce", descEN: "Log 500 total entries", descCS: "Zaznamenejte celkem 500 příjmů", icon: "circle.fill", category: "milestone", colorHex: "#8D6E63", textOverlay: "500"),
        AchievementDefinition(id: "entries_1000", titleEN: "Thousandaire", titleCS: "Tisícovka", descEN: "Log 1000 total entries", descCS: "Zaznamenejte celkem 1000 příjmů", icon: "circle.fill", category: "milestone", colorHex: "#FF8F00", textOverlay: "1K"),
        AchievementDefinition(id: "early_streak_3", titleEN: "Morning Ritual", titleCS: "Ranní rituál", descEN: "Log before 8 AM three days in a row", descCS: "Zaznamenejte před 8:00 tři dny v řadě", icon: "sun.max.fill", category: "milestone", colorHex: "#FFB74D", textOverlay: nil),
        AchievementDefinition(id: "weekend_warrior", titleEN: "Weekend Warrior", titleCS: "Víkendový bojovník", descEN: "Meet goal on both Saturday and Sunday", descCS: "Splňte cíl v sobotu i v neděli", icon: "calendar", category: "milestone", colorHex: "#66BB6A", textOverlay: nil),
        AchievementDefinition(id: "perfect_week", titleEN: "Perfect Week", titleCS: "Perfektní týden", descEN: "Meet goal all 7 days of the week", descCS: "Splňte cíl všech 7 dní v týdnu", icon: "checkmark.seal.fill", category: "milestone", colorHex: "#43A047", textOverlay: nil),
        AchievementDefinition(id: "challenge_5", titleEN: "Challenger", titleCS: "Vyzyvatel", descEN: "Complete 5 daily challenges", descCS: "Splňte 5 denních výzev", icon: "flag.fill", category: "challenge", colorHex: "#00897B", textOverlay: nil),
        AchievementDefinition(id: "challenge_20", titleEN: "Challenge Master", titleCS: "Mistr výzev", descEN: "Complete 20 daily challenges", descCS: "Splňte 20 denních výzev", icon: "flag.checkered", category: "challenge", colorHex: "#00695C", textOverlay: nil),
        AchievementDefinition(id: "xp_1000", titleEN: "XP Hunter", titleCS: "Lovec XP", descEN: "Earn 1000 total XP", descCS: "Získejte celkem 1000 XP", icon: "sparkles", category: "xp", colorHex: "#FFC107", textOverlay: nil),
        AchievementDefinition(id: "early_tester", titleEN: "Early Tester", titleCS: "Raný tester", descEN: "Using Fluidic before v1.0", descCS: "Používání Fluidic před v1.0", icon: "hammer.fill", category: "special", colorHex: "#9C27B0", textOverlay: nil),
    ]

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadSettings()
        seedAchievementsIfNeeded()
    }

    private func loadSettings() {
        guard let modelContext else { return }
        let descriptor = FetchDescriptor<UserSettings>()
        settings = (try? modelContext.fetch(descriptor))?.first
    }

    private func seedAchievementsIfNeeded() {
        guard let modelContext else { return }
        let descriptor = FetchDescriptor<Achievement>()
        let existing = (try? modelContext.fetch(descriptor)) ?? []
        let existingIds = Set(existing.map(\.achievementId))

        for def in Self.definitions {
            if existingIds.contains(def.id) {
                if let badge = existing.first(where: { $0.achievementId == def.id }) {
                    badge.colorHex = def.colorHex
                    badge.textOverlay = def.textOverlay
                }
            } else {
                let achievement = Achievement(
                    achievementId: def.id,
                    title: def.titleEN,
                    descriptionText: def.descEN,
                    iconName: def.icon,
                    category: def.category,
                    colorHex: def.colorHex,
                    textOverlay: def.textOverlay
                )
                modelContext.insert(achievement)
            }
        }
        try? modelContext.save()
    }

    func checkAchievements(
        todayTotal: Double,
        dailyGoal: Double,
        lastIntakeAmount: Double,
        streak: Int,
        totalEntries: Int,
        intakeHour: Int,
        locale: Locale,
        todayEntries: [WaterIntake],
        challengesCompleted: Int,
        totalXP: Int,
        appVersion: String
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
            case "streak_14":
                shouldUnlock = streak >= 14
            case "streak_30":
                shouldUnlock = streak >= 30
            case "streak_60":
                shouldUnlock = streak >= 60
            case "early_bird":
                shouldUnlock = intakeHour < 8
            case "night_owl":
                shouldUnlock = intakeHour >= 22
            case "midnight_sip":
                shouldUnlock = intakeHour >= 0 && intakeHour < 4
            case "big_gulp":
                shouldUnlock = lastIntakeAmount >= 500
            case "hydration_1L":
                shouldUnlock = todayTotal >= 1000
            case "hydration_5L":
                shouldUnlock = todayTotal >= 5000
            case "overachiever":
                shouldUnlock = todayTotal >= dailyGoal * 1.5
            case "double_goal":
                shouldUnlock = todayTotal >= dailyGoal * 2.0
            case "centurion":
                shouldUnlock = totalEntries >= 100
            case "entries_10":
                shouldUnlock = totalEntries >= 10
            case "entries_500":
                shouldUnlock = totalEntries >= 500
            case "entries_1000":
                shouldUnlock = totalEntries >= 1000
            case "early_streak_3":
                shouldUnlock = checkEarlyStreak3()
            case "weekend_warrior":
                shouldUnlock = checkWeekendWarrior()
            case "perfect_week":
                shouldUnlock = checkPerfectWeek()
            case "challenge_5":
                shouldUnlock = challengesCompleted >= 5
            case "challenge_20":
                shouldUnlock = challengesCompleted >= 20
            case "xp_1000":
                shouldUnlock = totalXP >= 1000
            case "early_tester":
                shouldUnlock = appVersion.hasPrefix("0.")
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

    // MARK: - Complex Badge Checks

    private func checkEarlyStreak3() -> Bool {
        guard let modelContext else { return false }
        let calendar = Calendar.current
        for dayOffset in 0..<3 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: calendar.startOfDay(for: .now)) else { return false }
            guard let eightAM = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: date) else { return false }
            let descriptor = FetchDescriptor<WaterIntake>(predicate: #Predicate<WaterIntake> { $0.timestamp >= date && $0.timestamp < eightAM })
            let count = (try? modelContext.fetchCount(descriptor)) ?? 0
            if count == 0 { return false }
        }
        return true
    }

    private func checkWeekendWarrior() -> Bool {
        guard let modelContext else { return false }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let weekday = calendar.component(.weekday, from: today)
        // weekday: 1=Sun, 7=Sat
        let daysToSaturday = (weekday + 6) % 7
        let daysToSunday = weekday == 1 ? 0 : (weekday - 1)
        guard let saturday = calendar.date(byAdding: .day, value: -daysToSaturday, to: today),
              let sunday = calendar.date(byAdding: .day, value: -daysToSunday, to: today) else { return false }
        let goal = settings?.dailyGoalML ?? 2500
        return totalForDate(saturday) >= goal && totalForDate(sunday) >= goal
    }

    private func checkPerfectWeek() -> Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let goal = settings?.dailyGoalML ?? 2500
        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { return false }
            if totalForDate(date) < goal { return false }
        }
        return true
    }

    private func totalForDate(_ date: Date) -> Double {
        guard let modelContext else { return 0 }
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return 0 }
        let descriptor = FetchDescriptor<WaterIntake>(predicate: #Predicate<WaterIntake> { $0.timestamp >= start && $0.timestamp < end })
        let entries = (try? modelContext.fetch(descriptor)) ?? []
        return entries.reduce(0) { $0 + $1.amount }
    }

    // MARK: - Queries

    func allAchievements() -> [Achievement] {
        guard let modelContext else { return [] }
        let descriptor = FetchDescriptor<Achievement>(sortBy: [SortDescriptor(\.category), SortDescriptor(\.achievementId)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func totalEntryCount() -> Int {
        guard let modelContext else { return 0 }
        let descriptor = FetchDescriptor<WaterIntake>()
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }

    func dismissToast() {
        newlyUnlocked = nil
    }
}
