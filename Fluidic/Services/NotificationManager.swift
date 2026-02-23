import Foundation
import UserNotifications

@Observable
final class NotificationManager {
    var isAuthorized = false

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            isAuthorized = granted
            return granted
        } catch {
            return false
        }
    }

    // MARK: - Smart (Adaptive) Reminders

    func scheduleAdaptiveReminders(
        currentIntakeML: Double,
        goalML: Double,
        activeHoursStart: Int,
        activeHoursEnd: Int,
        locale: Locale = Locale(identifier: "en")
    ) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        let remaining = goalML - currentIntakeML
        guard remaining > 0 else {
            scheduleCongratulation(locale: locale)
            return
        }

        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: .now)
        let hoursLeft = max(activeHoursEnd - max(currentHour, activeHoursStart), 1)
        let mlPerHour = remaining / Double(hoursLeft)

        let interval = mlPerHour > 300 ? 1 : 2
        var nextHour = currentHour + interval

        while nextHour < activeHoursEnd {
            var dateComponents = DateComponents()
            dateComponents.hour = nextHour
            dateComponents.minute = 0

            let remainingAtTime = remaining - (mlPerHour * Double(nextHour - currentHour))
            guard remainingAtTime > 0 else { break }

            let content = UNMutableNotificationContent()
            content.title = String(
                localized: "Time to hydrate!",
                locale: locale
            )
            content.body = String(
                localized: "You need about \(Int(mlPerHour)) ml per hour to reach your goal. Tap to log!",
                locale: locale
            )
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            let request = UNNotificationRequest(
                identifier: "fluidic-reminder-\(nextHour)",
                content: content,
                trigger: trigger
            )

            center.add(request)
            nextHour += interval
        }
    }

    // MARK: - Fixed Interval Reminders

    func scheduleFixedReminders(
        intervalHours: Double,
        activeHoursStart: Int,
        activeHoursEnd: Int,
        locale: Locale = Locale(identifier: "en")
    ) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        let intervalMinutes = Int(intervalHours * 60)
        var currentMinute = activeHoursStart * 60
        let endMinute = activeHoursEnd * 60
        var index = 0

        while currentMinute < endMinute {
            let hour = currentMinute / 60
            let minute = currentMinute % 60

            var dateComponents = DateComponents()
            dateComponents.hour = hour
            dateComponents.minute = minute

            let content = UNMutableNotificationContent()
            content.title = String(
                localized: "Time to hydrate!",
                locale: locale
            )
            content.body = String(
                localized: "Don't forget to drink water and stay hydrated!",
                locale: locale
            )
            content.sound = .default

            // repeats: true so these fire daily without the app being opened
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(
                identifier: "fluidic-fixed-\(index)",
                content: content,
                trigger: trigger
            )

            center.add(request)
            currentMinute += intervalMinutes
            index += 1
        }
    }

    // MARK: - Badge Unlocked

    func sendBadgeNotification(title: String, locale: Locale = Locale(identifier: "en")) {
        let content = UNMutableNotificationContent()
        content.title = String(
            localized: "Achievement Unlocked!",
            locale: locale
        )
        content.body = String(
            localized: "Achievement unlocked: \(title)",
            locale: locale
        )
        content.sound = .default

        // Fire immediately
        let request = UNNotificationRequest(
            identifier: "fluidic-badge-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Congratulation

    private func scheduleCongratulation(locale: Locale = Locale(identifier: "en")) {
        let content = UNMutableNotificationContent()
        content.title = String(
            localized: "Goal reached!",
            locale: locale
        )
        content.body = String(
            localized: "Amazing! You've hit your daily water intake goal. Keep it up!",
            locale: locale
        )
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "fluidic-congrats",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}
