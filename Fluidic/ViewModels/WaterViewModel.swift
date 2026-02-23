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
        try? modelContext.save()
        todayIntakes.append(intake)

        // Check if goal just reached
        if todayTotal >= dailyGoal && (todayTotal - ml) < dailyGoal {
            showCelebration = true
        }

        // Reschedule notifications
        if settings?.notificationsEnabled == true {
            scheduleReminders()
        }
    }

    func resetToday() {
        for intake in todayIntakes {
            modelContext.delete(intake)
        }
        try? modelContext.save()
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

        if todayTotal < dailyGoal {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: checkDate) else { return 0 }
            checkDate = yesterday
        }

        while true {
            let total = totalForDate(checkDate)
            if total >= dailyGoal {
                streak += 1
                guard let prevDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = prevDay
            } else {
                break
            }
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
        try? modelContext.save()
    }
}
