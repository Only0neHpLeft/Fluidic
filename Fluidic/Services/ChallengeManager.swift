import Foundation
import SwiftData

struct ChallengeDefinition {
    let textEN: String
    let textCS: String
    let check: (ChallengeContext) -> Bool
}

struct ChallengeContext {
    let todayTotal: Double
    let dailyGoal: Double
    let todayEntries: [WaterIntake]
    let yesterdayTotal: Double
    let activeHoursStart: Int
}

@Observable
final class ChallengeManager {

    private var modelContext: ModelContext?
    var todayChallenge: DailyChallenge?

    static let challenges: [ChallengeDefinition] = [
        // 0: Log before 9 AM
        ChallengeDefinition(textEN: "Log before 9 AM", textCS: "Zaznamenejte před 9:00") { ctx in
            ctx.todayEntries.contains { Calendar.current.component(.hour, from: $0.timestamp) < 9 }
        },
        // 1: Drink 3000 ml today
        ChallengeDefinition(textEN: "Drink 3000 ml today", textCS: "Vypijte dnes 3000 ml") { ctx in
            ctx.todayTotal >= 3000
        },
        // 2: Log 6 separate entries
        ChallengeDefinition(textEN: "Log 6 separate entries", textCS: "Zaznamenejte 6 záznamů") { ctx in
            ctx.todayEntries.count >= 6
        },
        // 3: Reach goal by 3 PM
        ChallengeDefinition(textEN: "Reach goal by 3 PM", textCS: "Splňte cíl do 15:00") { ctx in
            let hour = Calendar.current.component(.hour, from: Date())
            return ctx.todayTotal >= ctx.dailyGoal && hour < 15
        },
        // 4: Log at least 500 ml at once
        ChallengeDefinition(textEN: "Log at least 500 ml at once", textCS: "Zaznamenejte 500 ml najednou") { ctx in
            ctx.todayEntries.contains { $0.amount >= 500 }
        },
        // 5: Drink every 2 hours
        ChallengeDefinition(textEN: "Drink every 2 hours", textCS: "Pijte každé 2 hodiny") { ctx in
            let windows = Set(ctx.todayEntries.map { Calendar.current.component(.hour, from: $0.timestamp) / 2 })
            return windows.count >= 4
        },
        // 6: Start with 250 ml
        ChallengeDefinition(textEN: "Start with 250 ml", textCS: "Začněte s 250 ml") { ctx in
            guard let first = ctx.todayEntries.sorted(by: { $0.timestamp < $1.timestamp }).first else { return false }
            return first.amount >= 250
        },
        // 7: Reach 50% by noon
        ChallengeDefinition(textEN: "Reach 50% by noon", textCS: "Dosáhněte 50 % do poledne") { ctx in
            let noonEntries = ctx.todayEntries.filter { Calendar.current.component(.hour, from: $0.timestamp) < 12 }
            let noonTotal = noonEntries.reduce(0.0) { $0 + $1.amount }
            return noonTotal >= ctx.dailyGoal * 0.5
        },
        // 8: Log 8 times today
        ChallengeDefinition(textEN: "Log 8 times today", textCS: "Zaznamenejte 8 záznamů dnes") { ctx in
            ctx.todayEntries.count >= 8
        },
        // 9: Beat yesterday's total
        ChallengeDefinition(textEN: "Beat yesterday's total", textCS: "Překonejte včerejšek") { ctx in
            ctx.todayTotal > ctx.yesterdayTotal
        },
        // 10: Drink 2000 ml by 2 PM
        ChallengeDefinition(textEN: "Drink 2000 ml by 2 PM", textCS: "Vypijte 2000 ml do 14:00") { ctx in
            let entries = ctx.todayEntries.filter { Calendar.current.component(.hour, from: $0.timestamp) < 14 }
            return entries.reduce(0.0) { $0 + $1.amount } >= 2000
        },
        // 11: Log after 8 PM
        ChallengeDefinition(textEN: "Log after 8 PM", textCS: "Zaznamenejte po 20:00") { ctx in
            ctx.todayEntries.contains { Calendar.current.component(.hour, from: $0.timestamp) >= 20 }
        },
        // 12: Reach 120% of goal
        ChallengeDefinition(textEN: "Reach 120% of goal", textCS: "Dosáhněte 120 % cíle") { ctx in
            ctx.todayTotal >= ctx.dailyGoal * 1.2
        },
        // 13: No gaps > 3 hours
        ChallengeDefinition(textEN: "No gaps longer than 3 hours", textCS: "Bez mezer delších než 3 hodiny") { ctx in
            let sorted = ctx.todayEntries.sorted { $0.timestamp < $1.timestamp }
            guard sorted.count >= 2 else { return false }
            for i in 1..<sorted.count {
                if sorted[i].timestamp.timeIntervalSince(sorted[i-1].timestamp) > 3 * 3600 { return false }
            }
            return true
        },
        // 14: First entry within 30 min of waking
        ChallengeDefinition(textEN: "First entry within 30 min of waking", textCS: "První záznam do 30 min") { ctx in
            guard let first = ctx.todayEntries.sorted(by: { $0.timestamp < $1.timestamp }).first else { return false }
            let hour = Calendar.current.component(.hour, from: first.timestamp)
            let minute = Calendar.current.component(.minute, from: first.timestamp)
            let entryMinutes = hour * 60 + minute
            let wakeMinutes = ctx.activeHoursStart * 60
            return entryMinutes <= wakeMinutes + 30
        },
    ]

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadOrCreateTodayChallenge()
    }

    private func loadOrCreateTodayChallenge() {
        guard let modelContext else { return }
        let startOfDay = Calendar.current.startOfDay(for: .now)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!

        let descriptor = FetchDescriptor<DailyChallenge>(
            predicate: #Predicate<DailyChallenge> { $0.date >= startOfDay && $0.date < endOfDay }
        )
        if let existing = (try? modelContext.fetch(descriptor))?.first {
            todayChallenge = existing
        } else {
            let daysSinceEpoch = Int(startOfDay.timeIntervalSince1970 / 86400)
            let index = abs(daysSinceEpoch) % Self.challenges.count
            let challenge = DailyChallenge(date: startOfDay, challengeIndex: index)
            modelContext.insert(challenge)
            try? modelContext.save()
            todayChallenge = challenge
        }
    }

    func checkChallenge(context: ChallengeContext) -> Bool {
        guard let challenge = todayChallenge, !challenge.completed else { return false }
        let index = challenge.challengeIndex
        guard index >= 0, index < Self.challenges.count else { return false }

        if Self.challenges[index].check(context) {
            challenge.completed = true
            challenge.completedAt = Date()
            try? modelContext?.save()
            return true
        }
        return false
    }

    func challengeText(isCS: Bool) -> String {
        guard let challenge = todayChallenge else { return "" }
        let index = challenge.challengeIndex
        guard index >= 0, index < Self.challenges.count else { return "" }
        return isCS ? Self.challenges[index].textCS : Self.challenges[index].textEN
    }
}
