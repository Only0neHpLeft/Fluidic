import Foundation
import SwiftData
import SwiftUI

@Observable
final class WaterViewModel {
    private var modelContext: ModelContext
    let notifications = NotificationManager()

    var todayIntakes: [WaterIntake] = []
    var settings: UserSettings?
    var showCelebration = false
    var achievementManager = AchievementManager()
    var xpManager = XPManager()
    var challengeManager = ChallengeManager()

    var todayTotal: Double {
        todayIntakes.reduce(0) { $0 + $1.amount }
    }

    var dailyGoal: Double {
        settings?.dailyGoalML ?? 2500
    }

    var cupSize: Double {
        settings?.cupSizeML ?? 250
    }

    var progress: Double {
        guard dailyGoal > 0 else { return 0 }
        return min(todayTotal / dailyGoal, 1.0)
    }

    var greetingKey: LocalizedStringKey {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<21: return "Good evening"
        default: return "Good night"
        }
    }

    var appLocale: Locale {
        Locale(identifier: settings?.languageCode ?? "en")
    }

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadSettings()
        loadTodayIntakes()
    }

    func loadSettings() {
        let descriptor = FetchDescriptor<UserSettings>()
        let results = (try? modelContext.fetch(descriptor)) ?? []
        if let existing = results.first {
            settings = existing
        } else {
            let newSettings = UserSettings()
            modelContext.insert(newSettings)
            try? modelContext.save()
            settings = newSettings
        }
    }

    func loadTodayIntakes() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: .now)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let descriptor = FetchDescriptor<WaterIntake>(
            predicate: #Predicate<WaterIntake> { intake in
                intake.timestamp >= startOfDay && intake.timestamp < endOfDay
            },
            sortBy: [SortDescriptor(\.timestamp)]
        )
        todayIntakes = (try? modelContext.fetch(descriptor)) ?? []
    }

    func addWater(amount: Double? = nil) {
        let ml = amount ?? cupSize
        let intake = WaterIntake(amount: ml)
        modelContext.insert(intake)
        saveChanges()
        todayIntakes.append(intake)

        // Check if goal just reached
        let goalJustReached = todayTotal >= dailyGoal && (todayTotal - ml) < dailyGoal
        if goalJustReached {
            showCelebration = true
        }

        // Check achievements
        let hour = Calendar.current.component(.hour, from: Date())
        let totalEntries = achievementManager.totalEntryCount()
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.2"
        achievementManager.checkAchievements(
            todayTotal: todayTotal,
            dailyGoal: dailyGoal,
            lastIntakeAmount: intake.amount,
            streak: currentStreak(),
            totalEntries: totalEntries,
            intakeHour: hour,
            locale: appLocale,
            todayEntries: todayIntakes,
            challengesCompleted: settings?.challengesCompleted ?? 0,
            totalXP: settings?.totalXP ?? 0,
            appVersion: appVersion
        )

        // Award XP for badge unlocks
        if achievementManager.newlyUnlocked != nil {
            xpManager.awardXP(100, settings: settings)
        }

        // Award XP for logging water
        xpManager.awardXP(10, settings: settings)

        // Award XP if goal just reached
        if goalJustReached {
            xpManager.awardXP(50, settings: settings)
        }

        // Award XP for daily streak
        let streakVal = currentStreak()
        if streakVal > 0 && goalJustReached {
            xpManager.awardXP(20, settings: settings)
        }

        // Check daily challenge
        let calendar = Calendar.current
        let yesterdayDate = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: .now)) ?? Date()
        let ctx = ChallengeContext(
            todayTotal: todayTotal,
            dailyGoal: dailyGoal,
            todayEntries: todayIntakes,
            yesterdayTotal: totalForDate(yesterdayDate),
            activeHoursStart: settings?.activeHoursStart ?? 8
        )
        if challengeManager.checkChallenge(context: ctx) {
            xpManager.awardXP(75, settings: settings)
            settings?.challengesCompleted = (settings?.challengesCompleted ?? 0) + 1
        }

        // Check streak freeze award (every 7 days of streak)
        if streakVal > 0, streakVal % 7 == 0,
           streakVal > (settings?.lastStreakFreezeAwardedAt ?? 0),
           (settings?.streakFreezeCount ?? 0) < 3 {
            settings?.streakFreezeCount = (settings?.streakFreezeCount ?? 0) + 1
            settings?.lastStreakFreezeAwardedAt = streakVal
        }

        saveChanges()

        // Reschedule notifications
        if settings?.notificationsEnabled == true {
            scheduleReminders()
        }
    }

    func resetToday() {
        for intake in todayIntakes {
            modelContext.delete(intake)
        }
        saveChanges()
        todayIntakes = []
        showCelebration = false
    }

    func intakesForDate(_ date: Date) -> [WaterIntake] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let descriptor = FetchDescriptor<WaterIntake>(
            predicate: #Predicate<WaterIntake> { intake in
                intake.timestamp >= startOfDay && intake.timestamp < endOfDay
            }
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func totalForDate(_ date: Date) -> Double {
        intakesForDate(date).reduce(0) { $0 + $1.amount }
    }

    func weeklyData(for startOfWeek: Date) -> [(date: Date, total: Double)] {
        let calendar = Calendar.current
        return (0..<7).map { dayOffset in
            let date = calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek)!
            return (date: date, total: totalForDate(date))
        }
    }

    func currentStreak() -> Int {
        let calendar = Calendar.current
        var streak = 0
        var checkDate = calendar.startOfDay(for: .now)
        let frozenDates = settings?.frozenDates ?? []

        if todayTotal < dailyGoal {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: checkDate) else { return 0 }
            checkDate = yesterday
        }

        while true {
            let total = totalForDate(checkDate)
            if total >= dailyGoal {
                streak += 1
            } else if frozenDates.contains(where: { calendar.isDate($0, inSameDayAs: checkDate) }) {
                streak += 1 // frozen day counts
            } else {
                break
            }
            guard let prevDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = prevDay
        }

        return streak
    }

    func setupNotifications() async {
        guard settings?.notificationsEnabled == true else { return }
        let granted = await notifications.requestAuthorization()
        if granted {
            scheduleReminders()
        }
    }

    func scheduleReminders() {
        let mode = settings?.reminderMode ?? "smart"
        let start = settings?.activeHoursStart ?? 8
        let end = settings?.activeHoursEnd ?? 22

        if mode == "fixed" {
            notifications.scheduleFixedReminders(
                intervalHours: settings?.reminderIntervalHours ?? 1.5,
                activeHoursStart: start,
                activeHoursEnd: end,
                locale: appLocale
            )
        } else {
            notifications.scheduleAdaptiveReminders(
                currentIntakeML: todayTotal,
                goalML: dailyGoal,
                activeHoursStart: start,
                activeHoursEnd: end,
                locale: appLocale
            )
        }
    }

    func saveChanges() {
        do {
            try modelContext.save()
        } catch {
            print("Failed to save: \(error)")
        }
    }
}
