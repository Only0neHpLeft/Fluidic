import SwiftUI
import SwiftData

@main
struct FluidicApp: App {
    let container: ModelContainer

    init() {
        let schema = Schema([WaterIntake.self, UserSettings.self, Achievement.self, DailyChallenge.self])

        do {
            container = try ModelContainer(for: schema)
        } catch {
            print("Migration failed, recreating store: \(error)")
            Self.deleteDefaultStore()
            do {
                container = try ModelContainer(for: schema)
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }

    private static func deleteDefaultStore() {
        guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return }
        let storePath = appSupport.appendingPathComponent("default.store").path
        let fm = FileManager.default
        for suffix in ["", "-wal", "-shm"] {
            try? fm.removeItem(atPath: storePath + suffix)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
