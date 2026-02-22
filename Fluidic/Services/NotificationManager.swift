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

    func scheduleAdaptiveReminders(
        currentIntakeML: Double,
        goalML: Double,
        activeHoursStart: Int,
        activeHoursEnd: Int
    ) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        let remaining = goalML - currentIntakeML
        guard remaining > 0 else {
            scheduleCongratulation()
            return
        }

        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: .now)
        let hoursLeft = max(activeHoursEnd - max(currentHour, activeHoursStart), 1)
        let mlPerHour = remaining / Double(hoursLeft)

        // Schedule reminders every 1-2 hours during active hours
        let interval = mlPerHour > 300 ? 1 : 2
        var nextHour = currentHour + interval

        while nextHour < activeHoursEnd {
            var dateComponents = DateComponents()
            dateComponents.hour = nextHour
            dateComponents.minute = 0

            let remainingAtTime = remaining - (mlPerHour * Double(nextHour - currentHour))
            guard remainingAtTime > 0 else { break }

            let content = UNMutableNotificationContent()
            content.title = "Time to hydrate!"
            content.body = String(format: "You need about %.0f ml per hour to reach your goal. Tap to log!", mlPerHour)
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

    private func scheduleCongratulation() {
        let content = UNMutableNotificationContent()
        content.title = "Goal reached!"
        content.body = "Amazing! You've hit your daily water intake goal. Keep it up!"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "fluidic-congrats",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}
