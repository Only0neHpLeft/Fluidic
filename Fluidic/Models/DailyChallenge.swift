import Foundation
import SwiftData

@Model
final class DailyChallenge {
    var date: Date
    var challengeIndex: Int
    var completed: Bool
    var completedAt: Date?

    init(date: Date, challengeIndex: Int, completed: Bool = false, completedAt: Date? = nil) {
        self.date = date
        self.challengeIndex = challengeIndex
        self.completed = completed
        self.completedAt = completedAt
    }
}
