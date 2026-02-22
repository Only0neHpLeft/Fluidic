import Foundation
import HealthKit

@Observable
final class HealthKitManager {
    private let healthStore = HKHealthStore()
    var isAuthorized = false

    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestAuthorization() async -> Bool {
        guard isAvailable else { return false }

        let waterType = HKQuantityType(.dietaryWater)
        do {
            try await healthStore.requestAuthorization(toShare: [waterType], read: [waterType])
            isAuthorized = true
            return true
        } catch {
            return false
        }
    }

    func saveWaterIntake(milliliters: Double, date: Date = .now) async {
        guard isAuthorized else { return }

        let waterType = HKQuantityType(.dietaryWater)
        let quantity = HKQuantity(unit: .literUnit(with: .milli), doubleValue: milliliters)
        let sample = HKQuantitySample(type: waterType, quantity: quantity, start: date, end: date)

        do {
            try await healthStore.save(sample)
        } catch {
            // Silently fail — not critical
        }
    }

    func fetchTodayIntake() async -> Double {
        guard isAuthorized else { return 0 }

        let waterType = HKQuantityType(.dietaryWater)
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: .now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: .now, options: .strictStartDate)

        do {
            let descriptor = HKSampleQueryDescriptor(
                predicates: [.quantitySample(type: waterType, predicate: predicate)],
                sortDescriptors: [SortDescriptor(\.startDate)]
            )
            let samples = try await descriptor.result(for: healthStore)
            return samples.reduce(0.0) { $0 + $1.quantity.doubleValue(for: .literUnit(with: .milli)) }
        } catch {
            return 0
        }
    }
}
