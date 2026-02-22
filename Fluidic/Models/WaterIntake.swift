import Foundation
import SwiftData

@Model
final class WaterIntake {
    var id: UUID
    var amount: Double // milliliters
    var timestamp: Date

    init(amount: Double, timestamp: Date = .now) {
        self.id = UUID()
        self.amount = amount
        self.timestamp = timestamp
    }
}
